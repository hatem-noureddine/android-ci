# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker)](https://hub.docker.com/r/hateum/android-ci-box)
[![Docker Image Size](https://img.shields.io/docker/image-size/hateum/android-ci-box/latest?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

A modernized, high-performance, and lightweight Docker image designed for **Android Continuous Integration & Deployment (CI/CD)** pipelines (GitHub Actions, GitLab CI, Jenkins, Bitbucket Pipelines, etc.).

---

## ⚡ Highlights & Optimizations

- **🏎️ Ultra-Lightweight & Fast**: Streamlined specifically for modern Android builds. Stripped out legacy tools (Bower, Cordova, old Node, deprecated SDKs) to reduce download time and disk space.
- **🌐 Full Multi-Arch Support (`linux/amd64` and `linux/arm64`)**: Runs natively at maximum speed on Apple Silicon Macs (M1/M2/M3/M4), AWS Graviton, and standard x86_64 CI runners.
- **☕ Dual OpenJDK (17 & 21)**: Pre-installed OpenJDK 21 (default for AGP 8.8+ & 9.0) and OpenJDK 17 (headless to save space). Switch effortlessly with a single command.
- **📦 Modern Android SDK**: Command-line tools with pre-accepted licenses, API **34** & **35**, and Build-Tools **34.0.0** & **35.0.0**.
- **🚀 Complete Deployment Tooling**: Bundled with **Fastlane**, **Bundletool** (for AAB/APK operations), and the **GitHub CLI (`gh`)**.

---

## 🛠️ Installed Components & Versions

| Component | Version / Description |
| :--- | :--- |
| **Base OS** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Java JDKs** | OpenJDK 21 (Default) & OpenJDK 17 (Headless) |
| **Android SDK APIs** | API level 34 (Android 14) & API level 35 (Android 15) |
| **Android Build Tools**| `34.0.0`, `35.0.0` |
| **Android Platform Tools** | Latest `adb`, `fastboot`, etc. |
| **Deployment Tools** | Fastlane, Bundler, Bundletool (`1.18.1`) |
| **CLI Utilities** | GitHub CLI (`gh`), Git, Git LFS, cURL, Wget, Zip, Unzip, Build Essential |

---

## 🚀 Quick Start

### 1. Build an Android Project Locally
Mount your project root into `/project` and run Gradle:

```bash
docker run --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box \
  ./gradlew assembleRelease
```

### 2. Cache Gradle for Blazing Fast Consecutive Builds
To persist and reuse Gradle dependencies across runs, mount your local Gradle cache:

```bash
docker run --rm \
  -v "$(pwd)":/project \
  -v "$HOME/.gradle":/root/.gradle \
  -w /project \
  hateum/android-ci-box \
  ./gradlew check assembleRelease
```

---

## 💡 Practical Usage & Tips

### Switching JDK Version (17 vs 21)
The container defaults to **Java 21**. If your project or specific plugins require **Java 17**, use the built-in switch utility:

```bash
# Switch to JDK 17
switch-jdk 17

# Switch back to JDK 21
switch-jdk 21
```

Or set the environment variable directly in your CI step:
```bash
export JAVA_HOME=/opt/jdk-17
export PATH="$JAVA_HOME/bin:$PATH"
```

### Using Fastlane
Fastlane and Bundler are pre-installed and available globally:

```bash
docker run --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box \
  bundle exec fastlane beta
```

### Using Bundletool
A direct `bundletool` CLI wrapper is available:

```bash
# Generate APKs from an Android App Bundle (AAB)
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal
```

---

## 🔄 CI / CD Integration Examples

### GitHub Actions
```yaml
name: Android CI

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: hateum/android-ci-box:latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Run Unit Tests & Lint
        run: ./gradlew test lint

      - name: Build Release Bundle
        run: ./gradlew bundleRelease
```

### GitLab CI (`.gitlab-ci.yml`)
```yaml
image: hateum/android-ci-box:latest

stages:
  - test
  - build

variables:
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

cache:
  key: ${CI_COMMIT_REF_SLUG}
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
      - app/build/outputs/apk/
```

---

## 🚢 Publishing & Automated Builds

This repository includes a multi-arch automated build pipeline powered by GitHub Actions (`.github/workflows/docker-publish.yml`).

### Setup Docker Hub Publishing
1. In your GitHub repository, navigate to **Settings > Secrets and variables > Actions**.
2. Add the following repository secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username (`hateum`).
   - `DOCKERHUB_TOKEN`: A Docker Hub Personal Access Token (PAT) with `Read & Write` permissions.
3. Push to `main` or push a release tag (`v1.0.0`) to trigger the build and push automatically!

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
