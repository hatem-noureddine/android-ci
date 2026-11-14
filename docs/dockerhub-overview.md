# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Security](https://img.shields.io/badge/Trivy%20Audit-0%20Critical%20CVEs-brightgreen?style=flat-square&logo=security)](https://github.com/hatem-noureddine/android-ci/security)
[![Gradle](https://img.shields.io/badge/Gradle-9.8.2-02303A?style=flat-square&logo=gradle)](https://gradle.org)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-API%2035%20%7C%2036%20%7C%2037-34A853?style=flat-square&logo=android)](https://developer.android.com)
[![Java](https://img.shields.io/badge/OpenJDK-17%20%7C%2021%20(Default)-ED8B00?style=flat-square&logo=openjdk)](https://openjdk.org)
[![Fastlane](https://img.shields.io/badge/Fastlane-2.241.2-00F?style=flat-square&logo=fastlane)](https://fastlane.tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

A battle-tested, high-performance, and rootless Docker container engineered for **Android CI/CD automation** across **GitHub Actions**, **GitLab CI**, **Jenkins**, and **Bitbucket Pipelines**.

Features a **dual-mode network engine** (public internet & enterprise intranet with auto-proxy, custom CA certificates, and Nexus mirrors), **native multi-arch compilation** (`amd64` and `arm64`), and **zero-config dynamic auto-detection** of project SDK and Java toolchains.

---

## ⚖️ Why `hateum/android-ci-box`? (Feature Comparison)

| Capability | Standard Android CI Images | `hateum/android-ci-box` |
| :--- | :--- | :--- |
| **Silicon Architecture** | `x86_64` only (Emulated on ARM via slow QEMU) | **Native Multi-Arch (`amd64` + `arm64`)** (Full native silicon speed on Apple Silicon & AWS Graviton) |
| **Project Setup** | Manual SDK/JDK setup scripts per repo | **Zero-Config Dynamic Auto-Detection** (`compileSdk`, `buildTools`, Java 17/21) in <50ms |
| **Java Runtimes** | Single JDK version (fixed at build time) | **Dual-JDK (OpenJDK 21 + 17)** with instant CLI/Env toggle (`switch-jdk`) |
| **Security & Permissions**| Hardcoded `root` (fails on OpenShift/K8s) | **Universal Rootless (777 permissions)**, runs safely under any UID (`1000:0`, `1001:1001`) |
| **Vulnerability Audit** | Often contains unpatched high/critical CVEs | **Zero Unfixed Critical CVEs** (strictly audited via Trivy SARIF gates) |
| **Enterprise Network** | Custom Dockerfiles required for proxies & certs | **Auto-imported CA certs, automatic HTTP proxy & Nexus/Artifactory mirror derivation** |
| **Deployment Tools** | Slow `gem install fastlane` on every build | **Precompiled Ruby 4.0.9 + Fastlane 2.241.2** ready out-of-the-box in `/opt/rbenv` |
| **C/C++ NDK & CMake** | Missing or forces massive 4GB+ image size | **Dynamic On-Demand Engine (`install-ndk-version` & `INSTALL_NDK_VERSION`)** |
| **GitHub Action Integration** | Raw container scripting required | **Official Composite Action (`uses: hatem-noureddine/android-ci@v1`)** |
| **Build Performance Tuning** | Default Gradle daemon issues in Docker | **Auto-injected CI Optimization Init-Script (Parallel, Caching, VFS off)** |
| **Testing & Emulation** | Complex X11/VNC setup or broken display | **Native Gradle Managed Devices (GMD)** with SwiftShader Headless GPU acceleration |
| **Health Diagnostics** | No diagnostic tooling | **Built-in `ci-doctor` & `detect-android-project`** CLI utilities with JSON reporting |

---

## 🏛️ Architecture & 6-Tier Dependency Schema

```
+-----------------------------------------------------------------------------------------+
|                        Tier 1: Base Operating System (Ubuntu 24.04 LTS)                 |
|             Native Multi-Arch Matrix: linux/amd64 (x86_64) | linux/arm64 (aarch64)      |
+-----------------------------------------------------------------------------------------+
       |                                   |                                   |
       v                                   v                                   v
+------------------------+      +------------------------+      +------------------------+
|  Tier 2: Java Runtimes |      |  Tier 2: Ruby Runtime  |      | Tier 2: System Tools   |
| - OpenJDK 21 (Default) |      | - Ruby 4.0.9 (rbenv)   |      | - Python 3 & Pip (PEP) |
| - OpenJDK 17 (Instant) |      | - Bundler 4.0.23       |      | - GitHub CLI (gh)      |
| - switch-jdk helper    |      | - Fastlane 2.241.2     |      | - curl, git-lfs, zip   |
+------------------------+      +------------------------+      +------------------------+
       |                                   |                                   |
       +-----------------------------------+-----------------------------------+
                                           |
                                           v
+-----------------------------------------------------------------------------------------+
|                    Tier 3: Android Build Engine & Standalone CLI Tooling                |
| - Gradle 9.8.2 Standalone + Dynamic Gradle Wrapper Auto-Execution                       |
| - Android Gradle Plugin (AGP) 8.x & 9.x Fully Supported                                 |
| - Android SDK Platforms: android-35, android-36, android-37 (Pre-installed)             |
| - Android Build-Tools: 35.0.0, 36.0.0, 37.0.0 (Pre-installed)                           |
| - Google Android CLI ('android') & standalone Bundletool 1.18.3                         |
+-----------------------------------------------------------------------------------------+
                                           |
                                           v
+-----------------------------------------------------------------------------------------+
|                 Tier 4: Zero-Config Dynamic Project Auto-Detection Engine               |
| - detect-android-project: Scans build.gradle(.kts) & libs.versions.toml (<50ms)         |
| - Multi-module maximum aggregation: automatically resolves highest compileSdk           |
| - Auto-switches Java 17/21 and installs missing SDKs/build-tools on container startup   |
| - Cross-compatibility: Automatically forces Java 17 if Gradle Wrapper < 8.5 is detected|
+-----------------------------------------------------------------------------------------+
                                           |
                                           v
+-----------------------------------------------------------------------------------------+
|                      Tier 5: Automated Testing & Deployment Tooling                     |
| - Fastlane 2.241.2: Native Google Play Console deployment & lane automation             |
| - Gradle Managed Devices (GMD): SwiftShader Headless GPU & KVM Hardware Acceleration    |
| - Unit Testing, Android Lint & ProGuard/R8 bytecode optimization                        |
+-----------------------------------------------------------------------------------------+
                                           |
                                           v
+-----------------------------------------------------------------------------------------+
|                 Tier 6: Dual-Mode Universal Network & Rootless Security                 |
| - Mode 1: Public Internet (Direct unthrottled access to Google & Maven Central)         |
| - Mode 2: Enterprise Intranet (Auto-Proxy, Custom CA Import, Nexus/Artifactory Mirrors) |
| - Rootless Hardened: Universal 777 permissions (Runs under UID 1000:0, OpenShift, K8s)  |
| - Trivy Certified: 0 Unfixed Critical CVEs                                             |
+-----------------------------------------------------------------------------------------+
```

---

## ⚡ Quick Start by Developer Objective

### 1. Interactive Debugging & System Healthcheck
Verify container health, Java versions, SDK packages, and network connectivity in seconds:
```bash
# Run full interactive diagnostic with network connectivity probes
docker run --rm -v "$(pwd)":/project hateum/android-ci-box:latest ci-doctor

# Inspect project requirements vs installed components (<50ms)
docker run --rm -v "$(pwd)":/project hateum/android-ci-box:latest detect-android-project

# Launch interactive shell
docker run -it --rm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest /bin/bash
```

### 2. Build Release APK and Android App Bundle (AAB)
Zero manual setup: the container auto-configures JDK and SDK matching your project:
```bash
# Build Release APK
docker run --rm \
  -v "$(pwd)":/project \
  -v "$HOME/.gradle":/home/runner/.gradle \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew assembleRelease --no-daemon

# Build Release AAB and extract universal APK with Bundletool
docker run --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  bash -c "./gradlew bundleRelease --no-daemon && \
    bundletool build-apks --bundle=app/build/outputs/bundle/release/app-release.aab --output=/tmp/app.apks --mode=universal"
```

### 3. Instrumented UI Testing: Gradle Managed Devices (GMD)
Native headless emulator execution with SwiftShader GPU acceleration and KVM support:
```bash
docker run --rm \
  --device /dev/kvm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew pixel8api35DebugAndroidTest --no-daemon
```

### 4. Continuous Deployment with Fastlane
Deploy directly to Google Play Internal track without installing Ruby gems:
```bash
docker run --rm \
  -v "$(pwd)":/project \
  -w /project \
  -e SUPPLY_JSON_KEY_DATA="${PLAY_STORE_JSON_KEY}" \
  hateum/android-ci-box:latest \
  bundle exec fastlane android deploy_internal
```

---

## 🔍 Dynamic Auto-Detection & Cross-Compatibility Safeguards

The container includes a built-in static inspection engine (`detect-android-project`) executed by `entrypoint.sh` on startup:

1. **`compileSdk` Resolution**: Scans all sub-modules and selects the maximum target SDK. If missing from `/opt/android-sdk`, it auto-downloads it on-the-fly.
2. **`buildToolsVersion` Resolution**: Scans for explicit definitions or falls back to `${compileSdk}.0.0` (standard AGP behavior).
3. **Java Version Matching**: Selects OpenJDK 17 or 21 matching `jvmToolchain` or `JavaVersion.VERSION_XX`.
4. **Gradle ⇄ Java Compatibility Fallback**: If a project uses Gradle Wrapper < 8.5 (incompatible with Java 21), the container automatically switches to OpenJDK 17 to prevent build crashes.
5. **Air-Gapped Resiliency**: A 2-second network probe tests connectivity before downloading. If running offline, it warns and proceeds without freezing.

---

## 🎛️ CI Runtime Environment Variables

Explicit variables take **absolute precedence** over project auto-detection:

| Variable | Values / Format | Default | Purpose |
| :--- | :--- | :--- | :--- |
| `JAVA_VERSION` | `17`, `21` | `21` | Overrides active JDK (updates `JAVA_HOME` and symlinks). |
| `INSTALL_SDK_VERSION` | `33`, `34`, `35`, `36`, `37` | Auto-detected | Installs specified Android SDK platform if not present. |
| `INSTALL_BUILD_TOOLS` | `34.0.0`, `33.0.3`, ... | Auto-derived | Installs specified Android build-tools version. |
| `INSTALL_NDK_VERSION` | `27.2.12479018`, `26.1...` | Auto-detected | Installs specified Android NDK on-demand. |
| `INSTALL_CMAKE_VERSION` | `3.22.1`, `3.28...` | Auto-detected | Installs specified Android CMake on-demand. |
| `ENABLE_CI_OPTIMIZATIONS` | `true`, `false` | `true` | Enables/disables automatic Gradle CI parallel & build caching init-script. |
| `AUTO_DETECT_PROJECT` | `true`, `false` | `true` | Enables/disables static analysis of project build files. |
| `AUTO_INSTALL_SDK` | `true`, `false` | `true` | Allows/disallows on-the-fly downloading of missing SDK components. |
| `HTTP_PROXY` / `HTTPS_PROXY`| `http://proxy:8080` | *None* | Injected into `~/.gradle/gradle.properties` automatically. |
| `NO_PROXY` | `localhost,127.0.0.1,.corp` | *None* | Converted to Java pipe-delimited format for `gradle.properties`. |
| `NEXUS_URL` | `https://nexus.corp/repository`| *None* | Derives mirror hooks for Google, MavenCentral, GradlePortal. |
| `NEXUS_RUBY_URL` | `https://nexus.corp/rubygems` | Auto-derived | Configures Bundler and RubyGems mirror (auto-derived from `NEXUS_URL` if omitted). |
| `OFFLINE_MODE` | `true`, `false` | `false` | Opt-in: enforces strict offline build execution (`startParameter.offline=true`). |
| `CORPORATE_CA_URL` | URL string | *None* | Downloads and imports corporate SSL certificate on startup. |
| `INSECURE_CA_DOWNLOAD` | `true`, `false` | `false` | Disables TLS verification strictly during initial CA download if bootstrap cert is self-signed. |
| `GRADLE_BUILD_CACHE_URL` | URL string | *None* | Configures remote HTTP Gradle build caching in `init.d`. |

---

## 🛠️ CLI Utilities Reference

| Utility | Location | Usage Example | Purpose |
| :--- | :--- | :--- | :--- |
| `ci-doctor` | `/usr/local/bin/ci-doctor` | `ci-doctor [--summary \| --json]` | Complete system, Java, SDK, network, and project diagnostics. |
| `detect-android-project` | `/usr/local/bin/detect-android-project` | `detect-android-project [path] [--json]` | Ultra-fast (<50ms) static parser for compileSdk, buildTools, and JDK. |
| `switch-jdk` | `/usr/local/bin/switch-jdk` | `switch-jdk 17` or `source switch-jdk 21` | Seamlessly toggles between OpenJDK 17 and OpenJDK 21. |
| `install-sdk-version` | `/usr/local/bin/install-sdk-version` | `install-sdk-version 34` or `34.0.0` | Installs platforms or build-tools via Google Android CLI. |
| `install-ndk-version` | `/usr/local/bin/install-ndk-version` | `install-ndk-version 27.2.12479018 [cmake]` | Dynamically installs Android NDK and CMake with rootless permissions. |
| `bundletool` | `/usr/local/bin/bundletool` | `bundletool build-apks --bundle=app.aab` | Google Bundletool 1.18.3 CLI for universal APKs and testing. |
| `android` | `${ANDROID_HOME}/cmdline-tools/latest/bin/android` | `android sdk list`, `android --version` | Official Google Android CLI. |

---

## 🚀 CI/CD Pipeline Recipes

### 1. GitHub Actions (Official 1-Line Composite Action or Container Job)

#### Option A: Official GitHub Action (`uses: hatem-noureddine/android-ci@v1`)
```yaml
name: Android CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & Test Android App
        uses: hatem-noureddine/android-ci@v1
        with:
          run: |
            ci-doctor --summary
            ./gradlew lintRelease testReleaseUnitTest assembleRelease
```

#### Option B: Native Container Job (`container: image: hateum/android-ci-box:latest`)
```yaml
name: Android CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-24.04
    container:
      image: hateum/android-ci-box:latest
      options: --user 1000:0
    steps:
      - uses: actions/checkout@v4
      - uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*') }}
      - name: Run Diagnostics & Lint
        run: |
          ci-doctor --summary
          ./gradlew lintRelease testReleaseUnitTest --no-daemon
      - name: Build Release Bundle
        run: ./gradlew bundleRelease --no-daemon
      - name: Fastlane Google Play Deploy (Optional)
        run: bundle exec fastlane android deploy_internal
        env:
          SUPPLY_JSON_KEY_DATA: ${{ secrets.PLAY_STORE_JSON_KEY }}
```

### 2. GitLab CI/CD (`.gitlab-ci.yml`)
```yaml
default:
  image: hateum/android-ci-box:latest
  before_script:
    - export GRADLE_USER_HOME="${CI_PROJECT_DIR}/.gradle"
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .gradle/caches/
      - .gradle/wrapper/

stages: [ test, build ]

lint_and_test:
  stage: test
  script:
    - ci-doctor --summary
    - ./gradlew lintRelease testReleaseUnitTest --no-daemon

build_aab:
  stage: build
  script:
    - ./gradlew bundleRelease --no-daemon
  artifacts:
    paths:
      - app/build/outputs/bundle/release/*.aab
```
*For Jenkins, Bitbucket Pipelines, and CircleCI, see [`examples/ci/`](examples/ci/).*

---

## 🌐 Enterprise & Corporate Intranet Setup

### 1. SSL Inspection & Custom Corporate CA Certificates
Mount your enterprise certificates (`.crt`, `.cer`, `.pem`) into `/certificates`:
```bash
docker run --rm \
  -v /path/to/corporate-ca.crt:/certificates/corp.crt \
  hateum/android-ci-box:latest ./gradlew assembleRelease
```
Certificates are automatically registered in the system truststore and Java `cacerts`.

### 2. Nexus / Artifactory Mirror Auto-Derivation
Pass your internal repository URL to redirect Google Maven and MavenCentral automatically:
```bash
docker run --rm \
  -e NEXUS_URL="https://nexus.corp.internal/repository" \
  -e NEXUS_USER="ci-builder" \
  -e NEXUS_PASSWORD="secretPassword123" \
  hateum/android-ci-box:latest ./gradlew assembleRelease
```

---

## ❓ FAQ & Troubleshooting

### 1. Can I run on OpenShift, Kubernetes, or hardened runners?
Yes. Universal read/write permissions (`777`) are set on `/project`, `/builds`, `/opt`, and `/home/runner/.gradle`, allowing execution under any UID (e.g. `--user 1000:0` or `--user 1001:1001`).

### 2. How to fix SSL `PKIX path building failed`?
Mount your corporate certificate into `/certificates`:
`docker run -v /path/to/corp-cert.crt:/certificates/corp.crt hateum/android-ci-box:latest ...`

### 3. What is the status of the Android Emulator on ARM64 Linux hosts?
Google compiles the Linux SDK Emulator (`emulator`) exclusively for `x86_64`. On ARM64 Linux hosts (e.g. AWS Graviton), compilation, linting, unit tests, and Fastlane run at native silicon speed, while headless emulator tests require an `x86_64` runner.

---

## 📄 License
This project is open-source software licensed under the [MIT License](LICENSE).
