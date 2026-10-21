# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker)](https://hub.docker.com/r/hateum/android-ci-box)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fhateum-2088FF?style=flat-square&logo=github)](https://github.com/hatem-noureddine/android-ci/pkgs/container/android-ci)
[![Docker Image Size](https://img.shields.io/docker/image-size/hateum/android-ci-box/latest?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Gradle Version](https://img.shields.io/badge/Gradle-9.8.2-02303A?style=flat-square&logo=gradle)](https://gradle.org)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-API%2035%20%7C%2036%20%7C%2037-34A853?style=flat-square&logo=android)](https://developer.android.com)
[![Java](https://img.shields.io/badge/OpenJDK-17%20%7C%2021%20(Default)-ED8B00?style=flat-square&logo=openjdk)](https://openjdk.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

A modern, high-performance, and hardened Docker image engineered for **Android Continuous Integration and Delivery (CI/CD)** pipelines across **GitHub Actions**, **GitLab Runner**, **Jenkins**, and **Bitbucket Pipelines**.

It features an intelligent **dual-mode universal network engine** that works instantly out-of-the-box on the **public Internet** while automatically adapting to **secured enterprise intranet environments** (Nexus/Artifactory mirrors, SSL inspection with custom CA certificates, and HTTP/HTTPS corporate proxies).

---

## 🏛️ Image Architecture & Stack Overview

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                       hateum/android-ci-box:latest                            │
├───────────────────────────────────────────────────────────────────────────────┤
│  Base OS            : Ubuntu 24.04 LTS (Noble) | Multi-Arch: amd64 / arm64    │
├───────────────────────────────────────────────────────────────────────────────┤
│  ☕ Java Runtimes    : OpenJDK 21 (Default) + OpenJDK 17 (Instant switch)      │
│  🐘 Gradle Engine   : Gradle 9.8.2 (Standalone & Wrapper Support)             │
│  📱 Android SDK & CLI : APIs 35, 36, 37 + Google Android CLI ('android')      │
│  🎮 Emulator Engine  : Android SDK Headless Emulator + SwiftShader GPU        │
│  🚀 Deployment Tools: Fastlane, Bundletool 1.18.3, GitHub CLI (gh)            │
│  🐍 CI Tooling       : Python 3 & Pip (No PEP 668 restriction), Ruby          │
│  🩺 Health Diagnostic: Built-in 'ci-doctor' CLI utility                       │
├───────────────────────────────────────────────────────────────────────────────┤
│                      🌐 DUAL-MODE UNIVERSAL NETWORK ENGINE                    │
│  Mode 1 (Public)    : Direct unthrottled access to Google & Maven Central     │
│  Mode 2 (Enterprise): Auto-imported CA SSL + Auto Proxy + Nexus/Artifactory   │
├───────────────────────────────────────────────────────────────────────────────┤
│                      🛡️ ROOT & HARDENED NON-ROOT SECURITY                     │
│  Full arbitrary UID support (OpenShift, Kubernetes, hardened UID 1000:0)      │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start in 60 Seconds

### 1. Build an Android App Locally (One-Liner)
Mount your local Android project repository to `/project`:
```bash
docker run --rm \
  -v "$(pwd)":/project \
  -v "$HOME/.gradle":/home/runner/.gradle \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew assembleRelease
```

### 2. Launch an Interactive Debugging Shell
```bash
docker run -it --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  /bin/bash
```

### 3. Run the Built-In Diagnostics Tool
Validate your runtime, JDK versions, SDK packages, and network connectivity in seconds:
```bash
docker run --rm hateum/android-ci-box:latest ci-doctor
```

---

## ☕ Dual-JDK Switching (Java 17 ⇄ Java 21)

While OpenJDK 21 is active by default to leverage the fastest G1 Garbage Collector and modern JIT optimizations, you can toggle seamlessly to OpenJDK 17 whenever required by legacy Gradle plugins:

```bash
# Switch to OpenJDK 17
switch-jdk 17

# Switch back to OpenJDK 21
switch-jdk 21
```

Or declare it directly in your CI runner environment:
```yaml
environment:
  JAVA_HOME: "/opt/jdk-17"
```

---

## 🌐 Enterprise & Corporate Intranet Network Engine

The container inspects its environment at startup and automatically adapts without requiring custom build scripts or dockerfiles.

### 1. Corporate SSL Inspection & Custom CA Certificates
Mount your corporate root and intermediate CA certificates into `/certificates` (supports `.crt`, `.cer`, `.pem`):
```bash
docker run --rm \
  -v /path/to/my-company-ca.crt:/certificates/corp.crt \
  hateum/android-ci-box:latest ./gradlew assembleRelease
```
* The entrypoint automatically registers certificates into the Linux system truststore (`update-ca-certificates`).
* It automatically imports certificates into the active Java truststore (`cacerts` with `keytool`).

### 2. Corporate HTTP/HTTPS Proxy Auto-Detection
Pass your standard proxy environment variables:
```bash
docker run --rm \
  -e HTTP_PROXY="http://proxy.company.com:8080" \
  -e HTTPS_PROXY="http://proxy.company.com:8080" \
  -e NO_PROXY="localhost,127.0.0.1,.company.internal" \
  hateum/android-ci-box:latest ./gradlew assembleRelease
```
The entrypoint formats and writes `systemProp.http.*` and `systemProp.https.*` configurations directly into `~/.gradle/gradle.properties`.

### 3. Nexus & Artifactory Mirror Auto-Derivation Engine
Provide your internal Maven repository URL:
```bash
docker run --rm \
  -e NEXUS_URL="https://nexus.company.com" \
  -e NEXUS_USER="ci-builder" \
  -e NEXUS_PASSWORD="secretPassword123" \
  hateum/android-ci-box:latest ./gradlew assembleRelease
```
The entrypoint intercepts Google Maven, Maven Central, and Gradle Plugin Portal requests, automatically redirecting them to your enterprise internal mirror.

---

## 📱 Instrumented Testing: Gradle Managed Devices (GMD)

The image provides native, out-of-the-box support for **Gradle Managed Devices (GMD)**.

### 🌟 Key Advantages
1. **Zero Manual Scripts**: AGP provisions, boots headless, runs Espresso/UI Automator tests, records results, and terminates the emulator automatically.
2. **Pre-configured Headless GPU Acceleration**: The entrypoint injects `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` into `gradle.properties`, eliminating headless display crashes.
3. **CI Concurrency Protection**: `maxconcurrentdevices=1` is enforced to prevent runner Out-Of-Memory (OOM) errors.
4. **Hardware KVM Acceleration**: Pass `--device /dev/kvm` to leverage near-native hardware virtualization; software fallback activates automatically if KVM is absent.

### Configuration in your Android Project (`app/build.gradle` or `build.gradle.kts`)
```groovy
android {
    testOptions {
        animationsDisabled = true // Disables UI animations for faster and flake-free tests
        managedDevices {
            allDevices {
                // Standard smartphone (Android 15 / API 35) with lightweight Google ATD image
                pixel8api35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Pixel 8"
                    apiLevel = 35
                    systemImageSource = "google-atd"
                }

                // Foldable device (Android 16 / API 36)
                foldableApi36(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "7.6in Foldable"
                    apiLevel = 36
                    systemImageSource = "google"
                }
            }
            groups {
                allFormFactors {
                    targetDevices.add(allDevices.pixel8api35)
                    targetDevices.add(allDevices.foldableApi36)
                }
            }
        }
    }
}
```

### Execution Commands in CI
```bash
# Run tests on the standard Pixel 8 emulator
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew pixel8api35DebugAndroidTest

# Run tests on the 7.6in Foldable screen
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew foldableApi36DebugAndroidTest

# Run tests across all configured form-factors
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew allFormFactorsGroupDebugAndroidTest
```

---

## 🤖 AI Agent Integration (Antigravity, Claude Code, GitHub Copilot)

This repository is engineered for autonomous AI coding agents:
- **AI Agent Skill**: [`.agents/skills/android-ci-box/SKILL.md`](.agents/skills/android-ci-box/SKILL.md)
- **Agent Governance & Architecture Context**: [`AGENTS.md`](AGENTS.md)
- **Product Requirements Document (PRD)**: [`docs/PRD.md`](docs/PRD.md)
- **Architecture Decision Records (ADRs)**: [`docs/adr/`](docs/adr/)
- **Upstream Obsolescence & Dependency Watchdog**: [`.github/workflows/dependency-and-obsolescence-watch.yml`](.github/workflows/dependency-and-obsolescence-watch.yml)

### Supported Agent Workflows:
- **Environment Assessment**: Autonomous invocation of `ci-doctor` to identify missing SDK packages or KVM capabilities.
- **Automated JDK Switching**: Invocation of `switch-jdk 17` or `switch-jdk 21` when diagnosing bytecode compatibility issues.
- **Headless Build & Lint Execution**: Running `./gradlew assembleRelease bundleRelease test lintRelease` with non-daemon, optimal memory settings.
- **GMD Troubleshooting**: Automatically analyzing GMD failure logs and emulator kernel messages.
- **Automated Obsolescence Alerting**: Weekly automated GitHub Issues and Pull Requests when newer Gradle, AGP, or Bundletool versions are released.

To activate this skill in your AI assistant, point your agent to `.agents/skills/android-ci-box/SKILL.md`.

---

## 🚀 Ready-to-Use CI/CD Pipelines

### 1. GitLab CI (`.gitlab-ci.yml`)
```yaml
image: hateum/android-ci-box:latest

variables:
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .gradle/caches/
    - .gradle/wrapper/

stages:
  - test
  - build

unit_tests:
  stage: test
  script:
    - ci-doctor
    - ./gradlew test lintRelease check

build_apk:
  stage: build
  script:
    - ./gradlew assembleRelease bundleRelease
  artifacts:
    paths:
      - app/build/outputs/apk/release/*.apk
      - app/build/outputs/bundle/release/*.aab
    expire_in: 7 days
```

### 2. GitHub Actions (`.github/workflows/android-build.yml`)
```yaml
name: Android CI Build

on:
  push:
    branches: [ main, develop ]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: hateum/android-ci-box:latest
      options: --device /dev/kvm

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Cache Gradle Packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Environment Diagnostics & Tests
        run: |
          ci-doctor
          ./gradlew test lintRelease

      - name: Build APK & App Bundle
        run: ./gradlew assembleRelease bundleRelease

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: app/build/outputs/apk/release/*.apk
```

---

## ⚡ 360° Performance Architecture

| Optimization Pillar | Technical Implementation | CI & Developer Impact |
| :--- | :--- | :--- |
| **JVM Engine & GC** | OpenJDK 21 + `G1GC` + `-XX:+ParallelRefProcEnabled` + full C2 JIT | Reduces GC pause times; up to **2x faster** Kotlin and R8 compilation. |
| **Gradle Scheduling** | `org.gradle.parallel=true`, `org.gradle.caching=true`, `org.gradle.vfs.watch=false` | Maximum multi-core task parallelization and automated task output reuse. |
| **Image Slimming** | Purged documentation (`/usr/share/doc`, `/usr/share/man`), APT caches and gems | Ultra-fast `docker pull` on Kubernetes runners and ephemeral agents. |
| **Anti-SIGPIPE Stability** | Pre-calculated Android licenses and POSIX-compliant script execution | Eliminates `exit code 141` errors under strict shells with `set -o pipefail`. |
| **Shared Remote Cache** | Native support for `GRADLE_BUILD_CACHE_URL` in `init.d` | Instant cross-pipeline build cache sharing across enterprise teams. |

---

## ❓ FAQ & Troubleshooting

### 1. How to fix SSL `PKIX path building failed`?
This happens when your corporate proxy inspects SSL traffic with an internal certificate.
👉 **Fix**: Mount your corporate certificate into `/certificates`:
```bash
docker run -v /path/to/corp-cert.crt:/certificates/corp.crt hateum/android-ci-box:latest ...
```

### 2. Can I run on OpenShift or non-root runners?
Yes. The image is pre-configured with universal read/write permissions for arbitrary UIDs:
```bash
docker run --user 1000:0 hateum/android-ci-box:latest ...
```

### 3. How do I disable the Gradle Daemon?
The image ships with `org.gradle.daemon=false` enabled by default to prevent zombie daemon processes from consuming RAM on shared runners.

### 4. What is the status of the Android Emulator on ARM64 Linux runners?
Google compiles and releases the official Android SDK Emulator binary (`emulator`) exclusively for `linux/x86_64`. On ARM64 Linux hosts (e.g. AWS Graviton, Ampere), Android application compilation, APK/AAB generation, Android Lint, unit tests, and Fastlane lanes run at native ARM64 silicon speed, but headless emulator testing via GMD requires an `x86_64` runner.

---

## 📄 License
This project is open-source software licensed under the [MIT License](LICENSE).
