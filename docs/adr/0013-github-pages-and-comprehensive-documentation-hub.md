# ADR 0013: GitHub Pages (Docsify), Native Mermaid Diagrams and CI/CD Showcase

- **Status**: Accepted
- **Date**: 2026-11-14
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
As `hateum/android-ci-box` matured into a production-grade multi-architecture container supporting modern Android tooling (AGP 9.x, SDK 35/36/37, JDK 17/21, GMD, Fastlane 2.241.2, and AI Agent skills), the project needed:
1. A dedicated, interactive documentation website hosted on GitHub Pages with dark/light themes, instant search, and native Mermaid rendering.
2. Conversion of legacy ASCII architecture schemas in `README.md` into rich, natively rendered GitHub Mermaid diagrams.
3. Production-ready, copy-pasteable CI/CD configuration recipes for all major enterprise engines (GitHub Actions, GitLab CI, Jenkins, Bitbucket Pipelines, CircleCI, Azure DevOps).
4. Explicit documentation and playbooks for autonomous AI agents (Antigravity, Claude Code, Copilot, Roo Code) utilizing the embedded `.agents/skills/android-ci-box/SKILL.md`.
5. An ultra-fast standalone workflow to synchronize Docker Hub repository descriptions in ~10 seconds without triggering a 15-minute multi-arch container rebuild.

## Decision Drivers
- Zero-maintenance documentation architecture (zero compilation pipeline, fast client-side rendering via Docsify SPA).
- Professional GitHub repository showcase with populated metadata (About description, URL, and 12 targeted topics).
- Native GitHub and web rendering of diagrams using standard Mermaid syntax.
- Instant feedback loop for Docker Hub description updates via `workflow_dispatch`.

## Decision Outcome
1. **GitHub Pages with Docsify (`/docs`)**:
   - Deployed Docsify single-page application (`docs/index.html`) using Docsify v4, search plugin, copy-to-clipboard, pagination, and dark/light mode toggle.
   - Integrated Mermaid.js v10 dynamically to render complex diagrams client-side without compilation.
   - Added `docs/.nojekyll`, `docs/_sidebar.md`, and `docs/_navbar.md` for seamless navigation.
   - Published via GitHub Pages at `https://hatem-noureddine.github.io/android-ci/`.
2. **Mermaid Diagrams in `README.md` and Documentation**:
   - 6-Tier Architecture (`graph TD`)
   - Dual-Mode Network Lifecycle (`sequenceDiagram`)
   - Native Multi-Arch & Dynamic Auto-Detection (`flowchart TD`)
   - AI Agent Autonomous Execution Loop (`flowchart LR`)
   - Rootless POSIX Permissions Architecture (`graph LR`)
3. **Exhaustive CI/CD Recipes (`docs/ci-integrations.md`)**:
   - GitHub Actions (both Composite Action and Container Job mode)
   - GitLab CI/CD (`.gitlab-ci.yml`)
   - Jenkins Declarative Pipeline (`Jenkinsfile`)
   - Bitbucket Pipelines (`bitbucket-pipelines.yml`)
   - CircleCI (`.circleci/config.yml`)
   - Azure DevOps Pipelines (`azure-pipelines.yml`)
4. **AI Agent Playbook (`docs/ai-agents.md`)**:
   - Documented the closed-loop agent workflow: Inspect & Diagnose -> Autonomous Align -> Build & Test -> Analyze & Fix.
   - Comprehensive matrix of embedded CLI helpers (`ci-doctor`, `detect-android-project`, `switch-jdk`, `install-sdk-version`, `install-ndk-version`, `bundletool`).
5. **Standalone Docker Hub Description Sync (`dockerhub-sync-description.yml`)**:
   - Created a lightweight workflow running in ~10 seconds using the `Docker` environment secrets.
   - Triggers on `workflow_dispatch` and on pushes modifying `docs/dockerhub-overview.md`.
   - Updated `docker-publish.yml` to allow description synchronization on `workflow_dispatch`.
