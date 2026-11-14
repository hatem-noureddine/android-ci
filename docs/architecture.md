# Architecture & Technical Deep-Dive

This document details the internal design, multi-tier layout, network mechanics, and execution lifecycles of `hateum/android-ci-box`.

---

## 🏛️ 6-Tier Architecture Schema

The container is engineered as an immutable, optimized stack structured across 6 logical tiers:

```mermaid
graph TD
    classDef os fill:#2b3a4a,stroke:#4a6984,stroke-width:2px,color:#fff;
    classDef runtime fill:#1e4d6b,stroke:#2980b9,stroke-width:2px,color:#fff;
    classDef sdk fill:#145a32,stroke:#27ae60,stroke-width:2px,color:#fff;
    classDef security fill:#641e16,stroke:#c0392b,stroke-width:2px,color:#fff;
    classDef entrypoint fill:#512e5f,stroke:#8e44ad,stroke-width:2px,color:#fff;
    classDef agent fill:#7d6608,stroke:#f1c40f,stroke-width:2px,color:#fff;

    T1["<b>Tier 1: Base Operating System</b><br/>Ubuntu 24.04 LTS (Noble Numbat)<br/>Native Multi-Arch (amd64 / arm64)"]:::os

    T1 --> T2_Java["<b>Tier 2: Java Runtimes</b><br/>OpenJDK 21 (Default) & OpenJDK 17<br/>switch-jdk dynamic selector"]:::runtime
    T1 --> T2_Ruby["<b>Tier 2: Ruby & Deploy Tooling</b><br/>Precompiled Ruby 4.0.9 (rbenv)<br/>Bundler 4.0.23 + Fastlane 2.241.2"]:::runtime
    T1 --> T2_Sys["<b>Tier 2: System Utilities</b><br/>Python 3.12 (PEP 668), GitHub CLI (gh)<br/>curl, git-lfs, zip, unzip, POSIX ACLs"]:::runtime

    T2_Java --> T3["<b>Tier 3: Android Engine & Tooling</b><br/>• Gradle 9.8.2 standalone + Wrapper auto-run<br/>• Platforms: android-35, 36, 37.0 (alias 37)<br/>• Build-Tools: 35.0.0, 36.0.0, 37.0.0<br/>• Official Google Android CLI (cmdline-tools/latest)<br/>• Dynamic NDK (install-ndk-version)<br/>• Standalone Bundletool 1.18.3"]:::sdk
    T2_Ruby --> T3
    T2_Sys --> T3

    T3 --> T4["<b>Tier 4: Rootless Security & Hardening</b><br/>• Universal 777 & sticky-bit /opt permissions<br/>• Works under any arbitrary UID (OpenShift, K8s, GHA)<br/>• 0 Unfixed Critical CVEs (Trivy SARIF Gate)"]:::security

    T4 --> T5["<b>Tier 5: Dual-Mode Network Engine</b><br/>• Transparent public internet fallback<br/>• Auto-import CA certificates (/certificates)<br/>• Auto-derived HTTP/HTTPS Proxy & Java truststores<br/>• Nexus/Artifactory Gradle & Ruby mirror injection"]:::entrypoint

    T5 --> T6["<b>Tier 6: AI Agent Playbook & Helpers</b><br/>• .agents/skills/android-ci-box/SKILL.md<br/>• Diagnostic CLI suite: ci-doctor, detect-android-project<br/>• Gradle Managed Devices (GMD) with Headless SwiftShader"]:::agent
```

---

## 🌐 Dual-Mode Network Engine Lifecycle

The container operates autonomously whether running on the open public internet or behind strict corporate proxies with private mirrors:

```mermaid
sequenceDiagram
    autonumber
    participant Host as CI Runner / Agent
    participant Entry as entrypoint.sh
    participant Certs as /certificates (CA)
    participant Java as Java Truststore (cacerts)
    participant Gradle as ~/.gradle/init.d & gradle.properties
    participant Ruby as ~/.gemrc & Bundler
    participant App as Android Build Process

    Host->>Entry: docker run hateum/android-ci-box
    Note over Entry: Phase 1: Security & Workspace Sanitization
    Entry->>Entry: Verify POSIX permissions & sanitize input

    Note over Entry: Phase 2: Corporate CA Certificate Auto-Import
    alt Corporate CA or Insecure CA present
        Entry->>Certs: Scan *.crt, *.pem, or download CA
        Entry->>Java: keytool -importcert -trustcacerts -keystore cacerts
    end

    Note over Entry: Phase 3: Proxy & Mirror Auto-Derivation
    alt Enterprise Proxy defined (HTTP_PROXY / HTTPS_PROXY)
        Entry->>Gradle: Inject systemProp.http(s).proxyHost / proxyPort
        Entry->>Gradle: Sanitize & inject systemProp.http(s).nonProxyHosts
    end

    alt Enterprise Mirror defined (NEXUS_URL / CORPORATE_RUBY_MIRROR)
        Entry->>Gradle: Inject enterprise_mirrors.init.gradle
        Entry->>Ruby: Inject ~/.gemrc with internal gem mirror
    end

    Note over Entry: Phase 4: Dynamic Project Auto-Detection
    Entry->>App: detect-android-project (/project)
    Entry->>App: Align compileSdk, Java 17/21, switch-jdk if needed

    Entry->>App: exec "$@" (e.g. ./gradlew test, assembleRelease)
```

---

## ⚡ Native Multi-Arch & Dynamic Auto-Detection

```mermaid
flowchart TD
    Start([Host launches container]) --> ArchCheck{Detect CPU Architecture}
    
    ArchCheck -->|x86_64 / amd64| AMD["Run native amd64 binaries<br/>• Android SDK Emulator available<br/>• Full KMD / GMD hardware emulation"]
    ArchCheck -->|aarch64 / arm64| ARM["Run native arm64 binaries<br/>• Apple Silicon & AWS Graviton native speed<br/>• Emulator package omitted (Google limitation)"]

    AMD --> ScanProj[Scan Android project in /project]
    ARM --> ScanProj

    ScanProj --> DetectVersion{detect-android-project &lt;50ms}
    DetectVersion -->|compileSdk <= 34| LegacySDK["install-sdk-version &lt;api&gt; dynamically"]
    DetectVersion -->|compileSdk 35/36/37| PreinstalledSDK["Use pre-installed Android SDK 35/36/37"]
    
    DetectVersion -->|Toolchain Java 17| Switch17["switch-jdk 17"]
    DetectVersion -->|Toolchain Java 21| Switch21["Use default OpenJDK 21"]

    LegacySDK --> ExecuteBuild[Execute Gradle build / Fastlane lane]
    PreinstalledSDK --> ExecuteBuild
    Switch17 --> ExecuteBuild
    Switch21 --> ExecuteBuild
```

---

## 🔒 Rootless POSIX Permissions Architecture

In Kubernetes, OpenShift, or hardened GitHub Actions runners, containers run under arbitrary UIDs (such as `10001:0` or `1001:1001`) with no `root` capabilities:

```mermaid
graph LR
    subgraph Host["Host Environment (Arbitrary UID)"]
        User["UID: 10001 / GID: 0<br/>(No Root / No Sudo)"]
    end

    subgraph Container["hateum/android-ci-box (/opt & /home/runner)"]
        Workdir["/project (777)"]
        GradleHome["/home/runner/.gradle (777)"]
        AndroidAVD["/home/runner/.android (777)"]
        Certificates["/certificates (777)"]
        OptDir["/opt (1777 Sticky Bit)"]
    end

    User -->|Full Read/Write without permission denied| Workdir
    User -->|Cache reads & writes| GradleHome
    User -->|Headless GMD AVD files| AndroidAVD
    User -->|Dynamic CA placement| Certificates
    User -->|Dynamic NDK unpack| OptDir
```
