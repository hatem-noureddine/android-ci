---
name: android-ci-box
description: Autonomous operations, diagnostics, builds, lints, and test execution workflows inside the hateum/android-ci-box Android CI/CD container.
version: 1.1.0
triggers:
  - "build android"
  - "run android tests"
  - "switch jdk"
  - "install android sdk"
  - "gradle managed devices"
  - "ci-doctor"
  - "fastlane android"
---

# Android CI/CD Box AI Agent Skill

This skill guides AI agents (Antigravity, Claude Code, GitHub Copilot Workspace, Roo Code, etc.) to autonomously inspect, build, lint, and run instrumented tests for Android applications using the `hateum/android-ci-box` Docker container.

---

## 1. Container Specifications & Runtime Context

- **Docker Image**: `hateum/android-ci-box:latest` (or SemVer tag `1.1.0`)
- **Default Workdir**: `/project`
- **Default User**: `runner` (UID 1000, GID 0), fully hardened for rootless and arbitrary UID execution (`--user 1000:0`)
- **Default Java**: OpenJDK 21 (`/opt/jdk-21`), with OpenJDK 17 (`/opt/jdk-17`) available
- **Pre-installed Android SDK**:
  - Platforms: `android-35`, `android-36`, `android-37.0` (with alias `android-37`)
  - Build-Tools: `35.0.0`, `36.0.0`, `37.0.0`
  - Command-line Tools: Latest stable (`cmdline-tools/latest`)
  - Emulator: Android SDK Headless Emulator (`$ANDROID_HOME/emulator`)
- **Tooling**: Gradle 9.8.2, Bundletool 1.18.3, Fastlane, Python 3.12, GitHub CLI (`gh`)

---

## 2. Agent Operational Playbook

### Step 1: Healthcheck & Environment Diagnostics
Always run `ci-doctor` as the first diagnostic step before running any complex builds or debugging pipeline errors:

```bash
# Full environment diagnostic and network connectivity probe
ci-doctor

# Silent exit-code check for automated health checks
ci-doctor --summary
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

### Step 7: Fastlane & Bundletool Workflows

```bash
# Run Fastlane test lane
fastlane test

# Convert .aab to universal APK using bundletool
bundletool build-apks \
  --bundle=app/build/outputs/bundle/release/app-release.aab \
  --output=app/build/outputs/bundle/release/app-release.apks \
  --mode=universal
```

---

## 3. Agent Troubleshooting Guidelines

| Symptom | Probable Cause | Action |
| :--- | :--- | :--- |
| `Unsupported class file major version` | Incompatible Gradle and JDK version | Run `switch-jdk 17` or upgrade Gradle wrapper |
| `PKIX path building failed` | SSL inspection on corporate network | Mount CA certificate in `/certificates/corp.crt` |
| `compileSdk = 37 unsupported` | Outdated AGP version | Upgrade AGP to `9.4.1` or set `android.suppressUnsupportedCompileSdk=37` |
| Emulator crashes on launch | Missing KVM or headless GPU flag | Ensure `--device /dev/kvm` is passed and `swiftshader_indirect` is set |
| `exit code 141` in CI scripts | Broken pipe under `set -e -o pipefail` | Avoid piping commands like `fastlane --version \| head -n 1` |
