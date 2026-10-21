# Product Requirements Document (PRD)
## hateum/android-ci-box: The Autonomous Enterprise-Grade Android CI/CD Container

- **Document Version**: 1.2.0
- **Status**: Approved & In Production
- **Owner**: Hatem Noureddine (`hateum`)
- **Registries**: Docker Hub (`hateum/android-ci-box`) & GHCR (`ghcr.io/hatem-noureddine/android-ci-box`)

---

## 1. Executive Summary & Vision

### 1.1 The Problem
Android CI/CD engineering traditionally suffers from four acute pain points:
1. **Network Friction in Corporate Environments**: CI runners fail behind enterprise proxies, internal Nexus/Artifactory mirrors, and SSL-decrypting firewalls (causing `PKIX path building failed` errors).
2. **Slow, Inefficient Builds**: Unoptimized JVM garbage collection, lack of shared remote caching, and excessive image sizes cause pipeline execution times to exceed 15–30 minutes.
3. **Flaky Instrumented Testing**: Provisioning emulators manually via ad-hoc bash scripts, waiting for ADB boot triggers, and managing display headless rendering in containers is fragile and error-prone.
4. **Maintenance Overhead & Tooling Deprecations**: Fast-moving Google SDK changes (e.g., deprecation of `sdkmanager` in favor of `android CLI`, preview API requirements like `android.suppressUnsupportedCompileSdk`) break pipelines silently.

### 1.2 The Solution
`hateum/android-ci-box` is an ultra-fast, hardened, multi-architecture Docker image specifically tailored for Android CI/CD. It abstracts network complexity, provides zero-config support for **Gradle Managed Devices (GMD)**, embeds dual-JDK runtime switching (Java 17/21), and integrates directly with AI coding agents to enable fully autonomous project maintenance.

---

## 2. Target Personas

| Persona | Primary Needs & Jobs to be Done |
| :--- | :--- |
| **Android Mobile Engineer** | Fast local and CI feedback; reproducible test execution; seamless Gradle Managed Devices testing on phones and foldables. |
| **DevOps & Platform Engineer** | Zero permission leaks on OpenShift/Kubernetes (hardened non-root); transparent corporate proxy and CA certificate injection; multi-arch support (`amd64` / `arm64`). |
| **AI Coding Agent (Antigravity/Claude)** | Machine-readable CLI interfaces (`ci-doctor --summary`); standardized skills ([`SKILL.md`](../.agents/skills/android-ci-box/SKILL.md)); deterministic build and lint exit codes. |

---

## 3. Product Features & Requirements

### 3.1 Dual-Mode Universal Network Engine
- **Requirement 1.1 (Direct Internet Mode)**: The container must build Android apps on clean public cloud runners (GitHub Actions, GitLab SaaS) with zero configuration.
- **Requirement 1.2 (Corporate SSL Trust)**: Auto-import any `.crt`, `.cer`, or `.pem` mounted in `/certificates` into both Linux OS truststores and active Java truststores (`cacerts`).
- **Requirement 1.3 (Proxy Auto-Configuration)**: Parse `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` and automatically inject corresponding `systemProp.http.*` and `systemProp.https.*` into `gradle.properties`.
- **Requirement 1.4 (Mirror Auto-Derivation)**: Intercept Google Maven, Maven Central, and Gradle Plugin Portal requests, rerouting them to internal Nexus/Artifactory repositories via Gradle init scripts.

### 3.2 Automated Instrumented Testing with Gradle Managed Devices (GMD)
- **Requirement 2.1 (Headless GPU Virtualization)**: Pre-inject `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` into global Gradle settings.
- **Requirement 2.2 (Multi-Form Factor)**: Support standard phones (e.g., Pixel 8 with Google ATD images) and foldable screens (e.g., 7.6in Foldable with hinge emulation).
- **Requirement 2.3 (KVM Hardware Acceleration)**: Auto-detect `/dev/kvm` and set read/write permissions (`666`); provide graceful software fallback when KVM is unavailable.

### 3.3 Modernized Tooling & Google Android CLI
- **Requirement 3.1 (Android CLI Integration)**: Provide official Google `android` CLI alongside `sdkmanager` and `avdmanager`.
- **Requirement 3.2 (Dual-JDK Switching)**: Support instant switching between OpenJDK 21 (default) and OpenJDK 17 via `switch-jdk`.
- **Requirement 3.3 (AGP 9.x & SDK 37 Compatibility)**: Ensure out-of-the-box support for the latest Android Gradle Plugin (AGP 9.4.1), Gradle 9.8.2, Kotlin 2.4.20, and Android SDK APIs 35, 36, and 37.

---

## 4. Service Level Objectives (SLOs) & Quality Standards

- **Build Time Target**: Android sample project release compilation and unit testing in `< 45 seconds` on warm CI cache.
- **Security Vulnerability SLA**: **Zero unfixed critical CVEs** enforced on every build via Trivy scanning.
- **Static Analysis Gates**: **Zero warnings** across ShellCheck, Hadolint, and Actionlint.
- **Cross-Platform Availability**: 100% parity between `linux/amd64` and `linux/arm64` for application compilation and unit tests.
