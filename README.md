# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker)](https://hub.docker.com/r/hateum/android-ci-box)
[![Docker Image Size](https://img.shields.io/docker/image-size/hateum/android-ci-box/latest?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

A modernized, high-performance, and lightweight Docker image crafted for **Android Continuous Integration & Deployment (CI/CD)** pipelines (GitLab Runner, GitHub Actions, Jenkins, Bitbucket).

It features a **Universal Dual-Mode Network Engine** that runs out-of-the-box in **standard unrestricted Internet** environments, while automatically detecting and adapting to **corporate internal networks** (Nexus/Artifactory mirrors, SSL inspection / CA certificates, HTTP/HTTPS proxies).

---

## ⚡ Highlights & Key Features

- **🌐 Universal Dual-Mode Network Engine**:
  - **Standard Internet**: Works with zero configuration and zero latency using official Google and Maven repositories.
  - **Enterprise Intranet**: Auto-detects corporate CA certificates, HTTP/HTTPS proxies, and Nexus/Artifactory mirrors without breaking standard commands.
- **📱 Next-Gen Android SDK Support (All Verified Stable)**:
  - Pre-installed: **API 35 (Android 15)**, **API 36 (Android 16 / Baklava)**, and **API 37 (Android 17 / Cinnamon Bun)**.
  - Pre-installed Build-Tools: **35.0.0**, **36.0.0**, and **37.0.0**.
  - Built-in on-the-fly installer `install-sdk-version` for canary or custom packages.
- **🏎️ Multi-Arch Native Performance (`linux/amd64` and `linux/arm64`)**: Runs at full native speed on Apple Silicon (M1/M2/M3/M4), AWS Graviton, and standard x86_64 CI servers.
- **☕ Dual OpenJDK (17 & 21 Headless)**:
  - **OpenJDK 21** as default (standard for AGP 8.8+ & AGP 9.0).
  - **OpenJDK 17** switchable via `switch-jdk 17`.
- **⚡ Built-in Gradle CI Performance Tuning**:
  - `org.gradle.daemon=false` (prevents memory leaks and hung processes in CI).
  - `org.gradle.parallel=true` & `org.gradle.caching=true` (blazing fast parallel builds & caching).
  - `org.gradle.vfs.watch=false` (avoids useless inotify watcher overhead in containers).
  - Pre-tuned JVM flags (`-Xmx4g -XX:+UseG1GC -XX:+TieredCompilation`).
- **🛡️ Universal Root & Non-Root Support**:
  - Engineered for strict enterprise security policies (OpenShift, hardened Kubernetes, non-root GitLab Runners, arbitrary UIDs like `1000:0`).
  - World-writable Gradle home (`/home/runner/.gradle`) and workspace directories (`/builds`, `/project`) avoiding all "Permission Denied" crashes.
- **🩺 Integrated `ci-doctor` Diagnostic Tool**:
  - Single CLI command that validates in 1 second: Java versions, Android SDKs, build-tools, proxy status, CA certificates, and tests real HTTP connectivity to Google, Maven, and Nexus!
- **🛠️ Complete CI & Deployment Toolkit**:
  - **Fastlane & Bundler** (latest).
  - **Python 3** (`python3`, `pip`, `venv`) configured without PEP 668 restrictions.
  - **Bundletool** (`1.18.3`) with direct executable wrapper.
  - **GitHub CLI (`gh`)**, Git, Git LFS, cURL, Wget, Zip, Unzip.

---

## 🛠️ Installed Components & Verified Versions

| Component | Version / Description |
| :--- | :--- |
| **Base OS** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Android SDK Tools** | Latest Google Command-line Tools (`15859902`) |
| **Java JDKs** | OpenJDK 21 (Default) & OpenJDK 17 (Headless) |
| **Android SDK Platforms** | **API 35, 36, 37** (All stable) |
| **Android Build Tools**| `35.0.0`, `36.0.0`, `37.0.0` |
| **Android Platform Tools** | Latest `adb`, `fastboot`, etc. |
| **Bundletool** | Version `1.18.3` (Latest official release) |
| **Languages & Automation** | Ruby, Python 3 & Pip, Fastlane (latest), Bundler |
| **CLI Utilities** | GitHub CLI (`gh`), Git, Git LFS, cURL, Wget, Zip, Unzip, Build Essential |

---

## 🌐 Network Execution Modes

### Mode 1: Standard Unrestricted Internet
Run directly anywhere with internet access. No configuration required:
```bash
docker run --rm -v "$(pwd)":/project -w /project hateum/android-ci-box ./gradlew assembleRelease
```
The container accesses `dl.google.com`, `repo.maven.apache.org`, and `plugins.gradle.org` directly with zero overhead.

---

### Mode 2: Enterprise Internal Network (GitLab Runner / Private Intranet)
When executed inside a restricted enterprise network, the container automatically activates internal adapters:

#### 1. Corporate CA Certificates (SSL Inspection / Zscaler / Netskope)
Mount your corporate certificates into `/certificates` or provide the URL:
- **Volume mount**: `-v /path/to/my-ca.crt:/certificates/corp.crt`
- **Or CI Variable**: `CORPORATE_CA_URL: "https://pki.internal.domain/ca.crt"`

The entrypoint automatically runs `update-ca-certificates` AND imports them into Java's `$JAVA_HOME/lib/security/cacerts` keystore.

#### 2. Corporate HTTP / HTTPS Proxy
Define standard proxy environment variables in your runner:
```yaml
variables:
  HTTPS_PROXY: "http://proxy.internal.domain:8080"
  HTTP_PROXY: "http://proxy.internal.domain:8080"
  NO_PROXY: "localhost,127.0.0.1,.internal.domain"
```
The entrypoint automatically writes proxy parameters into `/root/.gradle/gradle.properties`.

#### 3. Nexus / Artifactory Multi-Repository & Auto-Detection
The container supports both **automatic sub-repository derivation** from a base URL and **multiple distinct repository URLs**:

- **Option A (Base URL Auto-Detection)**: Simply pass your Nexus host. The container will automatically derive standard Nexus 3 group and release endpoints (`/repository/maven-public/` and `/repository/maven-releases/`):
  ```yaml
  variables:
    NEXUS_URL: "https://nexus.internal.domain"
  ```
- **Option B (Multiple URLs)**: Declare multiple repositories separated by commas:
  ```yaml
  variables:
    NEXUS_URLS: "https://nexus.internal.domain/repository/maven-public/, https://nexus.internal.domain/repository/custom-android-libs/"
  ```
- **Authentication**: If your internal Nexus requires authentication, simply add:
  ```yaml
  variables:
    NEXUS_USER: "ci-user"
    NEXUS_PASSWORD: "$NEXUS_CI_PASSWORD"
  ```
  *(Credentials are applied automatically to all configured Nexus endpoints. If omitted, anonymous access is used).*

---

## 🦊 GitLab Runner Configuration (`.gitlab-ci.yml`)

```yaml
image: hateum/android-ci-box:latest

stages:
  - test
  - build

variables:
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .gradle/caches/
    - .gradle/wrapper/

before_script:
  - chmod +x ./gradlew

test:
  stage: test
  script:
    - ./gradlew test

build:
  stage: build
  script:
    - ./gradlew assembleRelease
  artifacts:
    paths:
      - app/build/outputs/apk/release/*.apk
```

---

## 💡 Practical CLI Commands

```bash
# Run CI Doctor diagnostics & connectivity check
ci-doctor

# Switch between JDK 17 and 21
switch-jdk 17
switch-jdk 21

# Install any custom or canary SDK package on the fly
install-sdk-version 37
install-sdk-version "build-tools;37.0.0"

# Build universal APKs from an AAB bundle
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal

# Run Fastlane
bundle exec fastlane internal_deploy
```

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
