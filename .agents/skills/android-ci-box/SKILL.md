---
name: android-ci-box
description: Autonomous operations, diagnostics, builds, lints, and test execution workflows inside the hateum/android-ci-box Android CI/CD container.
version: 1.7.3
triggers:
  - "build android"
  - "run android tests"
  - "ci-lane"
  - "ci summary"
  - "turnkey fastlane"
  - "badge android icon"
  - "distribute firebase"
  - "distribute playstore"
  - "switch jdk"
  - "install android sdk"
  - "gradle managed devices"
  - "ci-doctor"
  - "fastlane android"
  - "gitlab ci android"
  - "gitlab runner kvm"
  - "configure gitlab ci"
  - "github actions android"
  - "jenkins android"
  - "bitbucket pipelines android"
  - "circleci android"
---

# Android CI/CD Box AI Agent Skill

This skill guides AI agents (Antigravity, Claude Code, GitHub Copilot Workspace, Roo Code, etc.) to autonomously inspect, build, lint, and run instrumented tests for Android applications using the `hateum/android-ci-box` Docker container.

---

## 1. Container Specifications & Runtime Context

- **Docker Images**:
  - `hateum/android-ci-box:latest` (or SemVer tag `1.7.3`): Full batteries-included image with Android Emulator & GMD.
  - `hateum/android-ci-box:slim` (or SemVer tag `1.7.3-slim`): Ultra-fast compilation and linting image (~35% smaller).
- **Default Workdir**: `/project`
- **Default User**: `runner` (UID 1000, GID 0), fully hardened for rootless and arbitrary UID execution (`--user 1000:0`)
- **Default Java**: OpenJDK 21 (`/opt/jdk-21`), with OpenJDK 17 (`/opt/jdk-17`) available
- **Pre-installed Android SDK**:
  - Platforms: `android-35`, `android-36`, `android-37.0` (with alias `android-37`)
  - Build-Tools: `35.0.0`, `36.0.0`, `37.0.0`
  - Command-line Tools: Latest stable (`cmdline-tools/latest`)
  - Emulator: Android SDK Headless Emulator (`$ANDROID_HOME/emulator`)
- **Tooling**: Gradle 9.8.2, Bundletool 1.18.3, Fastlane 2.241.2, Ruby 4.0.9 (rbenv), Python 3.12, GitHub CLI (`gh`)

---

## 2. Agent Operational Playbook

### Step 1: Healthcheck & Environment Diagnostics
Always run `ci-doctor` as the first diagnostic step before running any complex builds or debugging pipeline errors:

```bash
# Full environment diagnostic and network connectivity probe
ci-doctor

# Fast, machine-readable JSON status report (<0.1s, no network delay)
ci-doctor --json
ci-doctor --summary
```

### Step 2: Zero-Code CI Runtime Version Selection & Project Auto-Detection
The container features an intelligent static analyzer (`detect-android-project`) that automatically reads `build.gradle(.kts)` and `libs.versions.toml` at startup to configure matching JDK, compileSdk, and build-tools versions.

You can also override or enforce versions directly via CI environment variables:

```bash
# Automatically switch to JDK 17 on container startup:
export JAVA_VERSION="17"

# Automatically install older/additional Android SDK platform on startup:
export INSTALL_SDK_VERSION="34"

# Automatically install specific Android build-tools version on startup:
export INSTALL_BUILD_TOOLS="34.0.0"

# Automatically install Android NDK & CMake on startup:
export INSTALL_NDK_VERSION="27.2.12479018"
export INSTALL_CMAKE_VERSION="3.22.1"

# Enterprise Nexus mirrors & offline execution:
export NEXUS_URL="https://nexus.corp/repository/maven-public"
export NEXUS_RUBY_URL="https://nexus.corp/repository/rubygems"
export OFFLINE_MODE="true" # Enforce strict offline operation

# Optional: Disable automatic static detection or auto-download if running air-gapped:
export AUTO_DETECT_PROJECT="false"
export AUTO_INSTALL_SDK="false"
```

To run the project analyzer standalone:
```bash
# Interactive overview of project targets vs installed SDKs:
detect-android-project /path/to/project

# Machine-readable JSON output:
detect-android-project /path/to/project --json
```

What `ci-doctor` checks:
- OS architecture (`amd64` / `arm64`) and execution user UID/GID.
- Active Java version and available JDK paths.
- Installed Android SDK platforms, build-tools, and emulator presence.
- Hardware virtualization (`/dev/kvm`) availability.
- Corporate proxy and internal Nexus/Artifactory repository injection status.

---

### Step 2: JDK Version Management
Android projects targeting legacy Android Gradle Plugins or specific libraries may require Java 17 instead of Java 21.

```bash
# Switch to OpenJDK 17
switch-jdk 17

# Switch back to OpenJDK 21
switch-jdk 21

# Inspect active Java version
java -version
```

---

### Step 3: Installing Additional SDK Versions on the Fly
If a project requires an older platform or build-tools version not pre-installed in the container:

```bash
# Install older platform (e.g., API 34)
install-sdk-version 34

# Install specific platform and build-tools
install-sdk-version 34 34.0.0
```

---

### Step 4: Building Android Applications

Always enforce headless, daemon-less builds in CI environments:

```bash
# Compile Release APK
./gradlew assembleRelease --no-daemon

# Compile Production Android App Bundle (.aab)
./gradlew bundleRelease --no-daemon

# Clean build with stacktrace for debugging
./gradlew clean assembleRelease --no-daemon --stacktrace
```

Output Artifact Paths:
- APK: `app/build/outputs/apk/release/*.apk`
- App Bundle: `app/build/outputs/bundle/release/*.aab`

---

### Step 5: Unit Testing & Android Linting

Run automated checks and inspect HTML/SARIF reports:

```bash
# Run unit tests and linting
./gradlew test lintRelease check --no-daemon

# Reports are generated at:
# - Unit Tests: app/build/reports/tests/testReleaseUnitTest/index.html
# - Lint HTML:  app/build/reports/lint-results-release.html
# - Lint SARIF: app/build/reports/lint-results-release.sarif
```

---

### Step 6: Instrumented Testing with Gradle Managed Devices (GMD)

The container is pre-configured for automated headless execution of Gradle Managed Devices without manual emulator boot scripts.

#### Docker Execution with KVM:
```bash
docker run --rm \
  --device /dev/kvm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew pixel8api35DebugAndroidTest
```

#### Pre-configured Environment Properties:
The container entrypoint automatically injects:
- `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` (prevents display crashes without X11)
- `android.testoptions.manageddevices.emulator.showKernelLogging=true`
- `android.experimental.testoptions.manageddevices.maxconcurrentdevices=1` (prevents CI runner OOM)

#### Device Profile Patterns in `build.gradle`:
```groovy
android {
    testOptions {
        animationsDisabled = true
        managedDevices {
            allDevices {
                pixel8api35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Pixel 8"
                    apiLevel = 35
                    systemImageSource = "google-atd"
                }
                foldableApi36(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "7.6in Foldable"
                    apiLevel = 36
                    systemImageSource = "google"
                }
            }
        }
    }
}
```

---

### Step 7: Fastlane & Turnkey `ci-lane` Workflows

Starting with **v1.7.0**, you do not need to configure a `Fastfile` in your repository. The image ships with built-in universal lanes orchestrated by the `ci-lane` CLI utility:

```bash
# List all available built-in lanes:
ci-lane list

# Run quality checks:
ci-lane test               # Run unit tests and extract reports
ci-lane lint               # Run Android Lint (HTML/SARIF)
ci-lane detekt             # Run Detekt static analysis
ci-lane sonar              # Run SonarQube analysis (requires SONAR_TOKEN)

# Build & Package:
ci-lane build_debug        # Assemble debug APK
ci-lane build_release      # Assemble release APK
ci-lane bundle             # Build release Android App Bundle (.aab)

# Dynamic Icon Badging:
ci-lane badge              # Overlays QA/BETA ribbon on launcher icons
# Environment variables:
# BADGE_TEXT="QA-42", BADGE_COLOR="#e74c3c", BADGE_GRAVITY="bottom", BADGE_SHIELD="v1.7.0"

# Code Signing:
ci-lane sign               # Decodes base64 keystore and sets signing properties
# Environment variables:
# KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD

# Stores & App Distribution:
ci-lane distribute_firebase  # Deploys to Firebase App Distribution
ci-lane distribute_playstore # Uploads AAB to Google Play Store (track: internal/alpha/beta/production)
ci-lane deploy_alpha         # Google Play internal track shortcut
ci-lane deploy_production    # Google Play production shortcut (default: 10% rollout, set PLAY_ROLLOUT_PERCENTAGE)
ci-lane distribute_github    # Attaches release APKs/AABs to GitHub Release
ci-lane app_center           # Distributes to Microsoft App Center (APPCENTER_API_TOKEN, APPCENTER_OWNER_NAME, APPCENTER_APP_NAME)
ci-lane deploy_huawei        # Publishes to Huawei AppGallery Connect (HUAWEI_CLIENT_ID, HUAWEI_CLIENT_SECRET, HUAWEI_APP_ID)
ci-lane deploy_samsung       # Publishes to Samsung Galaxy Store (SAMSUNG_SERVICE_ACCOUNT, SAMSUNG_ACCESS_KEY, SAMSUNG_CONTENT_ID)

# Version Control:
ci-lane changelog            # Generates CHANGELOG.md from Conventional Commits Git history
ci-lane git_tag              # Creates and pushes Git tag vX.Y.Z from app versionName

# Quality Metrics & Security:
ci-lane code_coverage        # Runs Jacoco and enforces minimum coverage threshold (COVERAGE_THRESHOLD, default: 80)
ci-lane security_scan        # Analyzes APK permissions and certificate expiry via apkanalyzer
ci-lane perf_baseline        # Runs Jetpack Macrobenchmark and writes metrics JSON (BENCHMARK_MODULE, BENCHMARK_OUTPUT)
ci-lane apk_size_audit       # Warns on APK/AAB size regressions vs baseline (APK_SIZE_BASELINE_MB, APK_SIZE_WARN_THRESHOLD_PCT)

# Multi-channel ChatOps:
ci-lane notify_slack         # Posts deployment status card to Slack (SLACK_WEBHOOK_URL)
ci-lane notify_teams         # Posts deployment status card to MS Teams (TEAMS_WEBHOOK_URL)
ci-lane notify               # Multi-channel broadcast to all configured webhooks

# Complete End-to-End Pipelines:
ci-lane all                  # Lint -> Detekt -> Test -> Build Release -> Bundle
ci-lane release              # sign + bundle + distribute (Play Store + Firebase) + git_tag + changelog + notify
```

*Note: If the current workspace contains its own `fastlane/Fastfile` or `Fastfile`, `ci-lane` automatically delegates to your custom Fastfile instead.*

#### Complete Lane Configuration Reference:
| Category | Lane | Environment Variables & Purpose |
| :--- | :--- | :--- |
| **Quality** | `test` | Runs JUnit tests across all modules. Parses results to summary. |
| | `lint` | Android Lint static analysis. Captures errors & warnings count. |
| | `detekt` | Detekt Kotlin static analysis. |
| | `sonar` | `SONAR_TOKEN` (*Required*), `SONAR_HOST_URL` (default: `https://sonarcloud.io`). |
| | `code_coverage` | `COVERAGE_THRESHOLD` (default: `80`): Fails build if Jacoco coverage % is below minimum. |
| | `security_scan` | Apkanalyzer audit for dangerous permissions and certificate expiry. |
| | `perf_baseline` | `BENCHMARK_MODULE`, `BENCHMARK_CLASS`, `BENCHMARK_OUTPUT`: Macrobenchmark JSON report. |
| **Packaging** | `build_debug` | Assembles debug APK. |
| | `build_release` | Assembles release APK. |
| | `bundle` | Assembles release Android App Bundle (.aab). |
| | `badge` | `BADGE_TEXT` (default: `BETA`), `BADGE_COLOR` (default: `#FF5722`), `BADGE_GRAVITY` (`bottom`/`top`). |
| | `apk_size_audit`| `APK_SIZE_BASELINE_MB`, `APK_SIZE_WARN_THRESHOLD_PCT` (default: 10%), `APK_SIZE_WARN_THRESHOLD_MB`. |
| **Signing** | `sign` | `KEYSTORE_BASE64` or `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. |
| **Stores** | `distribute_firebase` | `FIREBASE_APP_ID`, `FIREBASE_TOKEN`, `FIREBASE_GROUPS`, `FIREBASE_RELEASE_NOTES`. |
| | `distribute_playstore` | `GOOGLE_PLAY_KEY_BASE64` / `SUPPLY_JSON_KEY`, `PLAY_TRACK`, `PLAY_ROLLOUT_PERCENTAGE`. |
| | `deploy_alpha` | Shortcut for Google Play internal track (`PLAY_TRACK=internal`). |
| | `deploy_production` | Shortcut for Google Play production (`PLAY_ROLLOUT_PERCENTAGE`, default: 10%). |
| | `app_center` | `APPCENTER_API_TOKEN`, `APPCENTER_OWNER_NAME`, `APPCENTER_APP_NAME`, `APPCENTER_DISTRIBUTE_GROUP`. |
| | `deploy_huawei` | `HUAWEI_CLIENT_ID`, `HUAWEI_CLIENT_SECRET`, `HUAWEI_APP_ID`. |
| | `deploy_samsung` | `SAMSUNG_SERVICE_ACCOUNT`, `SAMSUNG_ACCESS_KEY`, `SAMSUNG_CONTENT_ID`. |
| | `distribute_github` | `GITHUB_REF_NAME` or `CI_COMMIT_TAG`: Uploads APK/AAB to GitHub Release. |
| **VCS** | `changelog` | `CHANGELOG_FILE` (default: `CHANGELOG.md`): Conventional Commits extractor. |
| | `git_tag` | `GIT_TAG_NAME` (optional override): Tags `vX.Y.Z` from app `versionName`. |
| **ChatOps** | `notify_slack` | `SLACK_WEBHOOK_URL`, `SLACK_CHANNEL`, `CI_BUILD_STATUS`. |
| | `notify_teams` | `TEAMS_WEBHOOK_URL`, `CI_BUILD_STATUS`. |
| | `notify` | Multi-channel broadcast to Slack, Teams, Discord, Telegram. |
| **Composite** | `all` | Full quality & build pipeline (`lint` -> `detekt` -> `test` -> `build_release` -> `bundle`). |
| | `release` | Full release pipeline (`sign` -> `bundle` -> `stores` -> `git_tag` -> `changelog` -> `notify`). |

#### Universal CI Summary & Sticky PR Comments:
`ci-lane` automatically generates an executive Markdown summary after every lane run:
- **GitHub Actions**: Injected into `$GITHUB_STEP_SUMMARY` and posted as a sticky PR comment (`<!-- ci-lane-summary -->`).
- **GitLab CI**: Written to `ci-lane-summary.md` and `build/reports/ci-lane-summary.md`. Posted to Merge Request notes via API.
- **Controls**: `CI_LANE_SUMMARY=true/false` (default: `true`), `CI_LANE_COMMENT_PR=true/false` (default: `true`), `CI_LANE_FAIL_SILENT=true/false` (default: `false`).
- Standalone CLI: `ci-lane-summary --lane <name> --status <success|failure> --duration <sec> --exit-code <code>`.

#### Bundletool Workflows:
```bash
# Convert .aab to universal APK using bundletool
bundletool build-apks \
  --bundle=app/build/outputs/bundle/release/app-release.aab \
  --output=app/build/outputs/bundle/release/app-release.apks \
  --mode=universal
```

---

### Step 8: Multi-Platform CI/CD Integration & Runner Setup

#### A. Turnkey GitLab CI/CD with `ci-lane` (`.gitlab-ci.yml`)
```yaml
stages: [quality, build, distribute, release]

default:
  image: hateum/android-ci-box:slim
  before_script:
    - export GRADLE_USER_HOME="${CI_PROJECT_DIR}/.gradle"
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .gradle/caches/
      - .gradle/wrapper/

pr_quality_gate:
  stage: quality
  script:
    - ci-lane lint
    - ci-lane test
    - ci-lane code_coverage
  artifacts:
    when: always
    paths:
      - ci-lane-summary.md
      - build/reports/ci-lane-summary.md

deploy_beta_firebase:
  stage: distribute
  only: [develop]
  script:
    - ci-lane badge
    - ci-lane build_release
    - ci-lane sign
    - ci-lane distribute_firebase
    - ci-lane notify_slack
  variables:
    BADGE_TEXT: "QA-${CI_PIPELINE_IID}"
    KEYSTORE_BASE64: "$PROD_KEYSTORE_B64"
    KEYSTORE_PASSWORD: "$KEYSTORE_PASSWORD"
    KEY_ALIAS: "$KEY_ALIAS"
    FIREBASE_APP_ID: "$FIREBASE_APP_ID"
    FIREBASE_TOKEN: "$FIREBASE_CLI_TOKEN"
    SLACK_WEBHOOK_URL: "$SLACK_WEBHOOK_URL"

publish_playstore_production:
  stage: release
  only: [tags]
  script:
    - ci-lane changelog
    - ci-lane bundle
    - ci-lane sign
    - ci-lane security_scan
    - ci-lane apk_size_audit
    - ci-lane deploy_production
    - ci-lane notify
  variables:
    KEYSTORE_BASE64: "$PROD_KEYSTORE_B64"
    KEYSTORE_PASSWORD: "$KEYSTORE_PASSWORD"
    KEY_ALIAS: "$KEY_ALIAS"
    GOOGLE_PLAY_KEY_BASE64: "$GOOGLE_PLAY_JSON_B64"
    PLAY_ROLLOUT_PERCENTAGE: "10"
    APK_SIZE_BASELINE_MB: "14.5"
    SLACK_WEBHOOK_URL: "$SLACK_WEBHOOK_URL"
    TEAMS_WEBHOOK_URL: "$TEAMS_WEBHOOK_URL"
```

#### B. Turnkey GitHub Actions with `ci-lane` (`.github/workflows/android.yml`)
```yaml
name: Android Turnkey CI/CD

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]
    tags: ['v*.*.*']

jobs:
  pr-quality:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    container:
      image: hateum/android-ci-box:slim
    permissions:
      contents: read
      pull-requests: write # For sticky PR comment
    steps:
      - uses: actions/checkout@v4
      - name: Run Quality Gate & Tests
        run: |
          ci-lane lint
          ci-lane test
          ci-lane code_coverage
        env:
          COVERAGE_THRESHOLD: "80"
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  beta-distribution:
    if: github.event_name == 'push' && github.ref == 'refs/heads/develop'
    runs-on: ubuntu-24.04
    container:
      image: hateum/android-ci-box:slim
    steps:
      - uses: actions/checkout@v4
      - name: Build, Badge & Deploy to Firebase
        run: |
          ci-lane badge
          ci-lane build_release
          ci-lane sign
          ci-lane apk_size_audit
          ci-lane distribute_firebase
          ci-lane notify_slack
        env:
          BADGE_TEXT: "BETA-${{ github.run_number }}"
          KEYSTORE_BASE64: ${{ secrets.PROD_KEYSTORE_B64 }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          FIREBASE_APP_ID: ${{ secrets.FIREBASE_APP_ID }}
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_CLI_TOKEN }}
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

  store-release:
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-24.04
    container:
      image: hateum/android-ci-box:slim
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run Full Store Release Pipeline
        run: ci-lane release
        env:
          KEYSTORE_BASE64: ${{ secrets.PROD_KEYSTORE_B64 }}
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          GOOGLE_PLAY_KEY_BASE64: ${{ secrets.PLAY_STORE_JSON_B64 }}
          PLAY_TRACK: "production"
          PLAY_ROLLOUT_PERCENTAGE: "10"
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

#### C. Jenkins (`Jenkinsfile`)
```groovy
pipeline {
    agent {
        docker {
            image 'hateum/android-ci-box:latest'
            args '-v /dev/kvm:/dev/kvm --user 1000:0'
        }
    }
    stages {
        stage('Build') {
            steps { sh './gradlew assembleRelease --no-daemon' }
        }
    }
}
```

---

## 3. Agent Troubleshooting Guidelines

| Symptom | Probable Cause | Action |
| :--- | :--- | :--- |
| `Unsupported class file major version` | Incompatible Gradle and JDK version | Run `switch-jdk 17` or upgrade Gradle wrapper |
| `PKIX path building failed` | SSL inspection on corporate network | Mount CA certificate in `/certificates/corp.crt` |
| `compileSdk = 37 unsupported` | Outdated AGP version | Upgrade AGP to `9.4.1` or set `android.suppressUnsupportedCompileSdk=37` |
| Emulator crashes on launch | Missing KVM or headless GPU flag | Ensure `--device /dev/kvm` is passed and `swiftshader_indirect` is set |
| `Cannot open /dev/kvm: Permission denied` | Host runner permissions restrict `/dev/kvm` | Run `sudo chmod 666 /dev/kvm` on runner host or add runner user to `kvm` group |
| `exit code 141` in CI scripts | Broken pipe under `set -e -o pipefail` | Avoid piping commands like `fastlane --version \| head -n 1` |
| Gradle Cache misses in GitLab CI | `GRADLE_USER_HOME` outside project dir | Export `GRADLE_USER_HOME="${CI_PROJECT_DIR}/.gradle"` in `before_script` |
| Bitbucket / CircleCI Out of Memory | Insufficient container RAM | Configure `size: 2x` (Bitbucket) or `resource_class: xlarge` (CircleCI) |

---

## 4. Deep-Dive References & Standards

For detailed operational guides, see the specialized references in this skill:
- **GitLab CI/CD Guide**: [`references/gitlab-ci.md`](references/gitlab-ci.md) (Complete `.gitlab-ci.yml`, Docker & Kubernetes Runner setups, caching patterns)
- **GitHub Actions Guide**: [`references/github-actions.md`](references/github-actions.md) (Container jobs, self-hosted KVM runners, caching, artifacts)
- **Jenkins Guide**: [`references/jenkins.md`](references/jenkins.md) (Declarative Jenkinsfile, Kubernetes agent Pod templates, KVM device passthrough)
- **Bitbucket Pipelines Guide**: [`references/bitbucket-pipelines.md`](references/bitbucket-pipelines.md) (2x resource sizing, custom caches, artifact handling)
- **CircleCI Guide**: [`references/circleci.md`](references/circleci.md) (xlarge resource class, Docker executor, store_test_results)
- **GMD & Emulators**: [`references/gmd-emulators.md`](references/gmd-emulators.md) (DSL patterns, ATD images, foldable/tablet profiles, KVM constraints)
- **Enterprise Networking**: [`references/enterprise-networking.md`](references/enterprise-networking.md) (Proxy routing, SSL truststore injection, internal mirrors)

### Ready-to-Use Templates:
- [Enterprise CI Templates Hub](file:///Users/hatemnoureddine/workspace/docker/android/ci-templates/README.md)
- [GitLab CI Pipeline & Component](file:///Users/hatemnoureddine/workspace/docker/android/ci-templates/gitlab/.gitlab-ci.yml)
- [Declarative Jenkinsfile](file:///Users/hatemnoureddine/workspace/docker/android/ci-templates/jenkins/Jenkinsfile)
- [Bitbucket Pipelines](file:///Users/hatemnoureddine/workspace/docker/android/ci-templates/bitbucket/bitbucket-pipelines.yml)
- [GitHub Actions Reusable Pipeline](file:///Users/hatemnoureddine/workspace/docker/android/ci-templates/github/android-ci-workflow.yml)

### External Official Documentation:
- [Google Android CLI (`android`)](https://developer.android.com/tools/android)
- [Gradle Managed Devices Documentation](https://developer.android.com/studio/test/gradle-managed-devices)
- [GitLab CI/CD Docker Executor](https://docs.gitlab.com/runner/executors/docker.html)
- [Jenkins Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [KubeVirt KVM Device Plugin for Kubernetes](https://github.com/kubevirt/device-plugin-kvm)

