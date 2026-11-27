# ADR 0026: Upgrade to Ubuntu 26.04 LTS (Resolute Raccoon) Base Image

- **Status**: Accepted
- **Date**: 2026-11-27
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
The Android CI/CD build box previously relied on **Ubuntu 24.04 LTS (Noble Numbat)** as its base image ([ADR-0002](0002-dual-mode-enterprise-network.md)).
With Canonical's general availability of **Ubuntu 26.04 LTS (Resolute Raccoon)** and the **26.04.1 point release**, upstream security patches, modern package toolchains, and Linux kernel enhancements become available for containerized workflows:
1. **Modern System Toolchain**: Upgraded system utilities, glibc, and package managers improve compilation and linking speeds.
2. **Extended Security Maintenance Horizon**: Ubuntu 26.04 LTS extends standard Canonical security maintenance through 2031 (and ESM through 2036).
3. **Multi-Architecture Consistency**: The container supports native `amd64` and `arm64` execution. When running on `arm64` hosts, x86_64 emulation relies on `libc6:amd64` and multiarch repositories. Previously, the suite name (`noble`) was hardcoded in Layer 1.

## Decision Drivers
- Stay aligned with Canonical's latest stable Long-Term Support (LTS) release.
- Maintain **zero unfixed critical vulnerabilities** in Trivy security audits.
- Preserve 100% backward compatibility for all embedded tooling:
  - Google Android CLI, Android SDK APIs (35, 36, 37.0), build-tools.
  - OpenJDK 17 and OpenJDK 21 runtimes (`switch-jdk`).
  - Precompiled Ruby 4.0.9 and Fastlane 2.241.2 (`ci-lane`).
  - Python 3 with PIL and virtualenv.
- Replace hardcoded distribution codenames with dynamic detection (`VERSION_CODENAME`) to ensure multiarch repositories automatically match the base image.

## Decision Outcome
1. **Base Image Migration**:
   - Updated `Dockerfile` Stage 1 base image from `ubuntu:24.04` to `ubuntu:26.04`.
2. **Dynamic Multi-Arch Suite Resolution**:
   - Replaced hardcoded `noble` APT repository strings with dynamic detection via `/etc/os-release`:
     ```bash
     UBUNTU_CODENAME=$(grep -oP 'VERSION_CODENAME=\K\w+' /etc/os-release || echo "resolute")
     ```
   - Dynamically injects `${UBUNTU_CODENAME}` suites for `arm64` multiarch sources, ensuring glibc consistency between architectures.
3. **Quality & Security Validation**:
   - Validated complete clean build on multi-architecture runners (`amd64` and `arm64`).
   - All 7 tests in `tests/test-image.sh` passed with 0 errors.
   - Trivy SARIF vulnerability gates confirmed 0 critical vulnerabilities.
4. **SemVer Version Increment**:
   - Bumped version to **`v1.8.0`** across `VERSION`, `ci-doctor`, and documentation.

## Consequences
- **Positive**: Long-term enterprise support window through 2031.
- **Positive**: Upgraded underlying glibc and core utilities while retaining full toolchain compatibility.
- **Positive**: ARM64 multiarch package sources automatically track the active Ubuntu release without manual code changes.
