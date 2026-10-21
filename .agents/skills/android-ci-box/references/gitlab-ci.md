# GitLab CI/CD Deep-Dive Guide (`hateum/android-ci-box`)

This reference provides production-ready configuration templates and operational guidance for running Android CI/CD pipelines and Gradle Managed Devices (GMD) with `hateum/android-ci-box` on GitLab Runner.

---

## 1. Complete Production `.gitlab-ci.yml`

This pipeline implements a multi-stage workflow: linting, unit testing, assembly, instrumented testing on GMD emulators, and release publishing.

```yaml
stages:
  - environment
  - quality
  - build
  - test_instrumented
  - publish

default:
  image: hateum/android-ci-box:latest
  before_script:
    - export GRADLE_USER_HOME="${CI_PROJECT_DIR}/.gradle"
    - chmod +x ./gradlew
  cache:
    key:
      files:
        - gradle/wrapper/gradle-wrapper.properties
        - "**/*.gradle*"
    paths:
      - .gradle/wrapper/
      - .gradle/caches/
    policy: pull-push

# --- Stage 1: Diagnostic & Sanity Check ---
ci_doctor:
  stage: environment
  script:
    - ci-doctor --summary
  cache: []

# --- Stage 2: Static Analysis & Unit Tests ---
lint_and_unit_tests:
  stage: quality
  script:
    - ./gradlew lintRelease testReleaseUnitTest check --no-daemon --stacktrace
  artifacts:
    name: "reports-${CI_COMMIT_SHORT_SHA}"
    when: always
    expire_in: 7 days
    reports:
      junit: app/build/test-results/testReleaseUnitTest/*.xml
    paths:
      - app/build/reports/lint-results-release.html
      - app/build/reports/lint-results-release.sarif
      - app/build/reports/tests/testReleaseUnitTest/

# --- Stage 3: Compilation (APK & AAB) ---
assemble_release:
  stage: build
  script:
    - ./gradlew assembleRelease bundleRelease --no-daemon
  artifacts:
    name: "binaries-${CI_COMMIT_SHORT_SHA}"
    expire_in: 14 days
    paths:
      - app/build/outputs/apk/release/*.apk
      - app/build/outputs/bundle/release/*.aab

# --- Stage 4: GMD Instrumented Tests (Requires KVM runner tag) ---
instrumented_tests:
  stage: test_instrumented
  tags:
    - kvm
    - android-emulator
  script:
    # Run tests on pre-configured Gradle Managed Device
    - ./gradlew pixel8api35DebugAndroidTest --no-daemon --info
  artifacts:
    name: "instrumented-reports-${CI_COMMIT_SHORT_SHA}"
    when: always
    expire_in: 7 days
    reports:
      junit: app/build/outputs/androidTest-results/managedDevice/**/*.xml
    paths:
      - app/build/reports/androidTests/managedDevice/
  rules:
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_PIPELINE_SOURCE == "merge_request_event"'

# --- Stage 5: Fastlane / Bundletool Distribution ---
distribute_internal:
  stage: publish
  script:
    # Convert .aab to universal APK for quick testing
    - bundletool build-apks --bundle=app/build/outputs/bundle/release/app-release.aab --output=app/build/outputs/bundle/release/app-release.apks --mode=universal
    # Run Fastlane distribution
    - fastlane supply --aab app/build/outputs/bundle/release/app-release.aab --track internal
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v[0-9]+\.[0-9]+\.[0-9]+$/'
```

---

## 2. GitLab Runner Configuration (`config.toml`)

To run headless Android emulators via Gradle Managed Devices or native emulator binaries, the GitLab Runner host must expose `/dev/kvm` and provide sufficient shared memory (`shm_size`).

### A. Docker Executor (Bare-Metal or Linux VM)

In `/etc/gitlab-runner/config.toml`:

```toml
concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "android-kvm-runner-01"
  url = "https://gitlab.example.com/"
  id = 123
  token = "glrt-YOUR_RUNNER_REGISTRATION_TOKEN"
  token_obtained_at = 2026-01-01T00:00:00Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "docker"
  tags = ["kvm", "android-emulator", "docker"]

  [runners.custom_build_dir]
  [runners.cache]
    MaxUploadedArchiveSize = 1073741824 # 1GB cache archive support
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]

  [runners.docker]
    tls_verify = false
    image = "hateum/android-ci-box:latest"
    privileged = false # Rootless safe: KVM does NOT require full privileged mode!
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = [
      "/cache",
      "/dev/kvm:/dev/kvm:rw" # Critical: Mount KVM device with read/write permissions
    ]
    devices = [
      "/dev/kvm" # Modern Docker device passthrough
    ]
    shm_size = 2147483648 # 2GB shm_size prevents Chromium/Skia emulator display crashes
    pull_policy = ["always", "if-not-present"]
```

> [!IMPORTANT]
> **Host Host-Side KVM Permissions**: Ensure the `gitlab-runner` user and containers have access to `/dev/kvm` on the host:
> ```bash
> sudo usermod -aG kvm gitlab-runner
> sudo chmod 666 /dev/kvm
> ```

---

### B. Kubernetes Executor (K8s Cluster with KVM Device Plugin)

In cloud-native Kubernetes environments, use the [KubeVirt KVM Device Plugin](https://github.com/kubevirt/device-plugin-kvm) to advertise `/dev/kvm` as a schedulable resource.

#### 1. GitLab Runner Helm `values.yaml` snippet:

```yaml
runners:
  config: |
    [[runners]]
      [runners.kubernetes]
        image = "hateum/android-ci-box:latest"
        privileged = false
        namespace = "gitlab-ci"
        poll_timeout = 600
        cpu_request = "4"
        cpu_limit = "8"
        memory_request = "8Gi"
        memory_limit = "16Gi"
        
        # Request KVM hardware virtualization
        [runners.kubernetes.node_resources]
          "devices.kubevirt.io/kvm" = "1"
        
        # Shared memory volume for emulator
        [[runners.kubernetes.volumes.empty_dir]]
          name = "dshm"
          mount_path = "/dev/shm"
          medium = "Memory"
```

---

## 3. Best Practices & Gotchas for GitLab CI

### 1. `GRADLE_USER_HOME` in Workspace
By default, Gradle uses `~/.gradle` (`/home/runner/.gradle`). In GitLab CI, caching directories outside `$CI_PROJECT_DIR` is not natively supported without volume mounts. Always export:
```yaml
before_script:
  - export GRADLE_USER_HOME="${CI_PROJECT_DIR}/.gradle"
```
The `entrypoint.sh` script automatically detects custom `GRADLE_USER_HOME` and configures enterprise proxy and mirror settings into that path seamlessly.

### 2. Entrypoint Execution in GitLab Runner
GitLab Runner executes steps by invoking `/bin/sh -c` or `bash -c`. Since `hateum/android-ci-box` defines `ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]` with `exec "$@"`, dynamic proxy injection, SSL certificate import, and permission hardening execute automatically before every GitLab CI command without developer intervention.

### 3. Memory & OOM Protection
Android builds and emulators are memory intensive. Set these parameters in your project's `gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=true
org.gradle.caching=true
android.experimental.testoptions.manageddevices.maxconcurrentdevices=1
```
