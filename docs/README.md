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

---

## ⚡ Quickstart (30 Seconds)

Execute a complete Android build inside the container:

```bash
docker run --rm -v "$(pwd):/project" hateum/android-ci-box:latest ./gradlew test lintRelease assembleRelease
```

Or run an interactive system diagnostic probe:

```bash
docker run --rm hateum/android-ci-box:latest ci-doctor
```

---

## 🧭 Documentation Pillars

<div class="card-grid">
  <div class="card">
    <h3>🏛️ Architecture & Lifecycles</h3>
    <p>6-tier architecture, native multi-arch matrix (<code>amd64</code> & <code>arm64</code>), dual-mode network agnosticism, and rootless POSIX permissions.</p>
    <p><a href="#/architecture">Explore Architecture →</a></p>
  </div>
  <div class="card">
    <h3>🚀 CI/CD Integrations</h3>
    <p>Production-ready, copy-pasteable configurations for GitHub Actions, GitLab CI, Jenkins, Bitbucket, CircleCI, and Azure DevOps.</p>
    <p><a href="#/ci-integrations">View CI Pipelines →</a></p>
  </div>
  <div class="card">
    <h3>🤖 AI Agents & Skills</h3>
    <p>Closed-loop diagnostic protocols and purpose-built CLI helpers designed for autonomous coding agents (Antigravity, Claude Code, Copilot).</p>
    <p><a href="#/ai-agents">Read Agent Playbook →</a></p>
  </div>
</div>

---

## 🌟 Key Highlights

* **Native Multi-Arch Speed**: Native silicon compilation on both `linux/amd64` (Intel/AMD) and `linux/arm64` (Apple Silicon & AWS Graviton).
* **Zero-Config Auto-Detection**: Instant scanner (`<50ms`) dynamically auto-detects `compileSdk`, `buildTools`, and Java 17/21 toolchains.
* **Dual-Mode Network Agnosticism**: Operates transparently on the public internet and behind strict corporate proxies (auto-CA import & Nexus mirrors).
* **Universal Rootless Security**: Universal `777` permissions and sticky-bit `/opt` allow seamless execution under arbitrary UIDs (e.g. `--user 1000:0` on OpenShift/K8s).
* **Precompiled Mobile Tooling**: Gradle 9.8.2 standalone, Fastlane 2.241.2 on Ruby 4.0.9, and Bundletool 1.18.3 ready out-of-the-box.
