# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker&color=0088ff)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Security](https://img.shields.io/badge/Trivy%20Audit-0%20Critical%20CVEs-brightgreen?style=flat-square&logo=security)](https://github.com/hatem-noureddine/android-ci/security)
[![Gradle](https://img.shields.io/badge/Gradle-9.8.2-02303A?style=flat-square&logo=gradle)](https://gradle.org)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-API%2035%20%7C%2036%20%7C%2037-34A853?style=flat-square&logo=android)](https://developer.android.com)
[![Java](https://img.shields.io/badge/OpenJDK-17%20%7C%2021%20(Default)-ED8B00?style=flat-square&logo=openjdk)](https://openjdk.org)
[![Fastlane](https://img.shields.io/badge/Fastlane-2.241.2-00F?style=flat-square&logo=fastlane)](https://fastlane.tools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hatem-noureddine/android-ci/blob/main/LICENSE)

A battle-tested, high-performance, and rootless Docker container engineered for **Android CI/CD automation** across **GitHub Actions**, **GitLab CI**, **Jenkins**, **Bitbucket Pipelines**, **CircleCI**, and **Azure DevOps**.

Features a **dual-mode network engine** (public internet & enterprise intranet with auto-proxy, custom CA certificates, and Nexus mirrors), **native multi-arch compilation** (`amd64` and `arm64`), **zero-config dynamic auto-detection** of project SDK and Java toolchains, and **built-in skills for AI coding agents**.

---

## 🚀 Quick Start (30 Seconds)

Run a complete Android build inside the container in one command:

```bash
docker run --rm -v "$(pwd):/project" hateum/android-ci-box:latest ./gradlew test lintRelease assembleRelease
```

Or run an interactive diagnostic probe:

```bash
docker run --rm hateum/android-ci-box:latest ci-doctor
```

---

## ⚖️ Why `hateum/android-ci-box`? (Feature Comparison)

| Capability | Standard Android CI Images | `hateum/android-ci-box` |
| :--- | :--- | :--- |
| **Silicon Architecture** | `x86_64` only (Emulated on ARM via slow QEMU) | **Native Multi-Arch (`amd64` + `arm64`)** (Full native speed on Apple Silicon & AWS Graviton) |
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
| **AI Agent Support** | No agent guidance or helpers | **AI Agent Skill (`.agents/skills`) & CLI helpers (`ci-doctor`, `detect-android-project`)** |

---

## 📚 Documentation Chapters

Explore the complete documentation:

- 🏛️ **[6-Tier Architecture & Diagrams](architecture.md)** — Architectural tiers, dual-mode network flowcharts, and rootless permission mechanics.
- 🛠️ **[CI/CD Integration Guides](ci-integrations.md)** — Ready-to-use recipes for GitHub Actions, GitLab CI, Jenkins, Bitbucket, CircleCI, and Azure DevOps.
- 🤖 **[AI Agents & Autonomous Workflows](ai-agents.md)** — Closed-loop execution loops and skill references for Antigravity, Claude Code, and Copilot.
- 📋 **[Architecture Decision Records (ADRs)](adr/README.md)** — Complete historical record of all technical choices.
- 🎯 **[Product Requirements Document (PRD)](PRD.md)** — Scope, requirements, and compliance metrics.
