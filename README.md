# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker)](https://hub.docker.com/r/hateum/android-ci-box)
[![Docker Image Size](https://img.shields.io/docker/image-size/hateum/android-ci-box/latest?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

A modernized, high-performance, and lightweight Docker image crafted for **Android Continuous Integration & Continuous Delivery (CI/CD)** pipelines, specifically optimized for **GitLab Runner** and internal enterprise networks (Nexus, Artifactory, SSL Inspection, Corporate Proxies).

---

## ⚡ Highlights & Key Features

- **🏎️ Multi-Arch Native Performance (`linux/amd64` and `linux/arm64`)**: Runs at maximum speed on Apple Silicon (M1/M2/M3/M4), AWS Graviton, and standard x86_64 CI servers.
- **📱 Next-Gen Android SDK Support**:
  - Pre-installed: **API 34, 35 (Android 15), 36 (Android 16 / Baklava)** and Build-Tools **34, 35, 36**.
  - Built-in on-the-fly installer `install-sdk-version` for **API 37** and early Google preview/canary SDKs.
- **☕ Dual OpenJDK (17 & 21 Headless)**:
  - **OpenJDK 21** as default (standard for AGP 8.8+ & AGP 9.0).
  - **OpenJDK 17** instantly switchable via `switch-jdk 17`.
  - Headless build strips X11/GUI bloat to minimize image size.
- **🏢 Enterprise & Internal Network Auto-Detection**:
  - **Automatic Corporate CA Truststore Injection**: Drops any `.crt` or `.pem` mounted in `/certificates` directly into the Linux system store AND Java's `cacerts` truststore.
  - **Automatic Nexus / Artifactory Mirroring**: Auto-generates Gradle mirror init scripts when `NEXUS_URL` or `INTERNAL_MAVEN_URL` is set.
  - **Automatic Corporate Proxy Configuration**: Injects HTTP/HTTPS proxy parameters directly into `gradle.properties`.
- **🛠️ Complete CI & Deployment Toolkit**:
  - **Fastlane & Bundler** (latest).
  - **Python 3** (`python3`, `pip`, `venv`) configured without PEP 668 restrictions.
  - **Bundletool** (`1.18.1`) with direct executable wrapper.
  - **GitHub CLI (`gh`)**, Git, Git LFS, cURL, Wget, Zip, Unzip.

---

## 🛠️ Installed Components & Versions

| Component | Version / Description |
| :--- | :--- |
| **Base OS** | Ubuntu 24.04 LTS (Noble Numbat) |
| **Java JDKs** | OpenJDK 21 (Default) & OpenJDK 17 (Headless) |
| **Android SDK Platforms** | API 34 (Android 14), API 35 (Android 15), API 36 (Android 16), API 37 ready |
| **Android Build Tools**| `34.0.0`, `35.0.0`, `36.0.0` |
| **Android Platform Tools** | Latest `adb`, `fastboot`, etc. |
| **Languages & Tooling** | Ruby (latest), Python 3 & Pip, Fastlane, Bundler, Bundletool (`1.18.1`) |
| **CLI Utilities** | GitHub CLI (`gh`), Git, Git LFS, cURL, Wget, Zip, Unzip, Build Essential |

---

## 🦊 GitLab Runner Integration (Internal Network)

This image is engineered specifically to run seamlessly on **GitLab Runner** (Docker executor), including compatibility with `/builds` volume permissions and corporate network environments.

### 1. Minimal `.gitlab-ci.yml` Example
```yaml
image: hateum/android-ci-box:latest

stages:
  - test
  - build

variables:
  # Store Gradle dependencies inside the GitLab CI build directory to cache them
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .gradle/caches/
    - .gradle/wrapper/

before_script:
  - chmod +x ./gradlew

unit_tests:
  stage: test
  script:
    - ./gradlew test

build_release:
  stage: build
  script:
    - ./gradlew assembleRelease
  artifacts:
    paths:
      - app/build/outputs/apk/release/*.apk
```

---

### 2. Enterprise Network Features (Nexus, Proxy, Corporate CA)

You don't need custom wrapper scripts or Docker modifications. Simply set GitLab CI/CD variables in **Settings > CI/CD > Variables**:

#### A. Internal Nexus / Artifactory Mirror
Set the following variables:
- `NEXUS_URL`: `https://nexus.internal.domain/repository/maven-public/`
- *(Optional)* `NEXUS_USER` & `NEXUS_PASSWORD`

The container automatically generates `/root/.gradle/init.d/nexus-mirror.init.gradle` on startup, redirecting all Gradle repositories to your internal mirror.

#### B. Corporate CA Certificates (SSL Inspection / Zscaler / Netskope)
Mount your company certificate into `/certificates` or provide the URL:
- **Option 1 (Volume mount)**: Mount your CA into `/certificates/corp-ca.crt`.
- **Option 2 (Variable)**: Set `CORPORATE_CA_URL: "https://pki.internal.domain/corporate-root.crt"`.

The entrypoint automatically runs `update-ca-certificates` AND imports the certificate into Java's `$JAVA_HOME/lib/security/cacerts` keystore, preventing `PKIX path building failed` errors!

#### C. Corporate HTTP / HTTPS Proxy
Set standard runner variables:
- `HTTPS_PROXY`: `http://proxy.internal.domain:8080`
- `HTTP_PROXY`: `http://proxy.internal.domain:8080`
- `NO_PROXY`: `localhost,127.0.0.1,.internal.domain`

The container automatically writes these proxy settings into `gradle.properties`.

---

## 💡 Practical CLI Utilities & Commands

### 1. Installing Android API 37 or Preview Packages on the Fly
If your project targets Android 37 or a canary release:
```bash
# Install platform 37 and matching build-tools
install-sdk-version 37

# Or install any arbitrary SDK package
install-sdk-version "build-tools;36.0.0-rc1"
```

### 2. Switching Java Version (17 vs 21)
The container defaults to **Java 21**. If your build requires **Java 17**:
```bash
# Switch to JDK 17
switch-jdk 17

# Switch back to JDK 21
switch-jdk 21
```

### 3. Deploying with Fastlane
Fastlane and Bundler are pre-installed globally:
```bash
bundle exec fastlane internal_deploy
```

### 4. Working with App Bundles (Bundletool)
```bash
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal
```

---

## 🚢 Publishing the Docker Image

The repository includes a multi-arch automated build pipeline via GitHub Actions (`.github/workflows/docker-publish.yml`).

### Setup Docker Hub Publishing
1. In your GitHub repository ([`hatem-noureddine/android-ci`](https://github.com/hatem-noureddine/android-ci)), navigate to **Settings > Secrets and variables > Actions**.
2. Add the following repository secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username (`hateum`).
   - `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token.
3. Push to `main` or push a release tag (`v1.0.0`) to trigger the build and push automatically!

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
