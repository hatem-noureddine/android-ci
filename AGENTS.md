# AI Agents Operational Guidelines & Architecture Context (`AGENTS.md`)

Welcome, AI Agent! This document defines the engineering standards, architectural constraints, and operational protocols for autonomous agents (Antigravity, Claude Code, GitHub Copilot Workspace, Roo Code, etc.) developing and maintaining the `hateum/android-ci-box` repository.

---

## 1. Project Mission & Identity

- **Repository**: `https://github.com/hatem-noureddine/android-ci`
- **Docker Registries**:
  - Primary: `hateum/android-ci-box` (Docker Hub)
  - Mirror: `ghcr.io/hatem-noureddine/android-ci-box` (GitHub Container Registry)
- **Goal**: Provide the most reliable, secure, high-performance, and network-resilient Docker image for Android CI/CD pipelines, supporting modern Google tooling (AGP 9.x, Android SDK 35/36/37, Gradle Managed Devices, Google Android CLI) with zero manual friction.

---

## 2. Core Architectural Principles (Non-Negotiable)

When writing code, Dockerfiles, or shell scripts in this repository, you **MUST** adhere to the following rules:

### A. Dual-Mode Network Agnosticism
- The container must work seamlessly out-of-the-box on the public Internet without requiring corporate variables.
- When enterprise variables (`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, `NEXUS_URL`, `CORPORATE_CA_URL`) are present, [entrypoint.sh](entrypoint.sh) must configure Gradle and Java truststores automatically without developer intervention.

### B. Rootless & Hardened Security (Zero Permission Leaks)
- Never assume root execution. All workspaces (`/project`, `/builds`, `/home/runner/.gradle`, `/certificates`, `/home/runner/.android/avd`) must maintain universal read/write permissions (`777` or POSIX ACLs) so that arbitrary UIDs (e.g., OpenShift `--user 1000:0` or `--user 1001:1001`) never encounter `Permission denied`.
- Security scans via **Trivy** must maintain **0 unfixed critical vulnerabilities**. Faux-positives must be strictly documented in [.trivyignore](.trivyignore) with full justification.

### C. Multi-Architecture Compatibility (`amd64` vs `arm64`)
- Always account for multi-architecture builds.
- **Critical Architecture Quirk**: Google publishes the Linux Android SDK Emulator package (`emulator`) **only for `x86_64` (`amd64`)**. On `arm64`, the emulator package does not exist in Google's repository. In the `Dockerfile` and `tests/test-image.sh`, always condition emulator installation and testing to `amd64`, while ensuring core compilation, linting, and unit tests run at full native speed on `arm64`.

### D. Semantic Versioning (SemVer)
- The single source of truth for the project version is the root [VERSION](VERSION) file.
- Any new features, deprecation updates, or fixes must bump [VERSION] (Major, Minor, or Patch).
- GitHub releases (`vX.Y.Z`) and Docker tags (`latest`, `X.Y.Z`, `X.Y`, `X`, `sha-<commit>`) are automatically derived from this file.

---

## 3. Strict Linter & Quality Gates

Before pushing any commit, you **MUST** verify that all static analysis tools report **zero warnings and zero errors**:

```bash
# 1. ShellCheck (all shell scripts must pass with 0 warnings)
shellcheck bin/* ci-doctor entrypoint.sh tests/test-image.sh

# 2. Hadolint (Dockerfile linter)
docker run --rm -i hadolint/hadolint:latest hadolint --ignore DL3008 --ignore DL3028 - < Dockerfile

# 3. Actionlint (GitHub Actions workflows validator)
docker run --rm -v "$(pwd):/repo" --workdir /repo rhysd/actionlint:latest

# 4. Android Compilation & Unit Tests
cd test_projects/SampleProject && ./gradlew test lintRelease check assembleRelease --no-daemon
```

---

## 4. Operational Playbook & Available Helpers

The image provides specialized CLI utilities that you should leverage when automating Android workflows:

| Utility | Location | Purpose |
| :--- | :--- | :--- |
| `ci-doctor` | `/usr/local/bin/ci-doctor` | Complete diagnostic tool for Java, SDK, KVM, proxy, and mirrors. Always run first when debugging. |
| `switch-jdk` | `/usr/local/bin/switch-jdk [17\|21]` | Toggles between OpenJDK 17 and OpenJDK 21 dynamically. |
| `install-sdk-version` | `/usr/local/bin/install-sdk-version <api>` | Installs older/preview SDK platforms using the new `android sdk` CLI with `sdkmanager` fallback. |
| `bundletool` | `/usr/local/bin/bundletool` | Standalone wrapper for Google's Bundletool 1.18.3. |
| `android` | `${ANDROID_HOME}/cmdline-tools/latest/bin/android` | Official Google Android CLI (modern replacement for sdkmanager/avdmanager). |

---

## 5. Decision Records & Further Reading

- **Product Requirements Document (PRD)**: [`docs/PRD.md`](docs/PRD.md)
- **Architecture Decision Records (ADRs)**: [`docs/adr/`](docs/adr/)
- **AI Agent Skill**: [`.agents/skills/android-ci-box/SKILL.md`](.agents/skills/android-ci-box/SKILL.md)
