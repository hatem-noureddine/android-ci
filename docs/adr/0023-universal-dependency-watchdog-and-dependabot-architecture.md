# ADR 0023: Universal Dependency Watchdog, GitHub Actions Audit and Automated Pull Request Architecture

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
To maintain high security, performance, and compatibility across modern Google tooling (AGP 9.x, Android SDK 35/36/37, JDK 17/21, Fastlane, and Node 24 actions), the Android CI Box relies on a wide matrix of upstream dependencies.
Historically:
1. Upstream monitoring was limited to three standalone components (Gradle, Bundletool, AGP) checked via basic regex curl queries.
2. Changes across the Ruby ecosystem (Fastlane, Bundler), Python packages (pip, setuptools, wheel), and Git LFS were tracked manually.
3. GitHub Actions defined across `.github/workflows/` lacked automated version auditing, leading to runtime deprecation warnings (such as the Node 20 deprecation).
4. Maintainers required an automated mechanism to receive notifications via GitHub Issues and continuous automated Pull Requests (MRs) whenever upstream updates become available.

## Decision Drivers
- Deliver 100% automated coverage of all container components and workflow actions.
- Adopt a dual-engine architecture combining GitHub's native Dependabot with an intelligent, multi-ecosystem watchdog scanner.
- Surface an executive Markdown dashboard directly in `$GITHUB_STEP_SUMMARY`.
- Ensure idempotency: create or update existing GitHub Issues and dispatch tested Pull Requests without human intervention.
- Guarantee zero external runtime dependencies by using standard Python 3 libraries exclusively.

## Decision Outcome
1. **GitHub Native Dependabot Configuration (`.github/dependabot.yml`)**:
   - Enabled native `github-actions` ecosystem scanning running weekly every Monday at 05:00 UTC.
   - Enabled native `docker` ecosystem scanning to monitor base image updates (`ubuntu:24.04`).
   - Standardized commit prefixes (`ci(deps): ...`, `chore(docker): ...`) and labeling (`dependencies`, `github-actions`).
2. **Universal Upstream Watchdog Scanner (`scripts/check-upstream-dependencies.py`)**:
   - Implemented an autonomous, zero-dependency Python scanner that inspects:
     - **Build Engines**: Gradle (`services.gradle.org`).
     - **Android Framework**: AGP stable channels (`dl.google.com/android/maven2`).
     - **Android Tooling**: Google Bundletool releases (`google/bundletool`).
     - **Ruby & Mobile Deployment**: Fastlane & Bundler (`rubygems.org`).
     - **Python Base Tools**: pip, setuptools, wheel (`pypi.org`).
     - **VCS Utilities**: Git LFS (`git-lfs/git-lfs`).
     - **Workflow Actions**: Parses all `.github/workflows/*.yml` for `uses:` directives and verifies latest stable release tags via the GitHub API.
   - Supports `--apply` mode to update safe, non-breaking parameters directly in `Dockerfile`.
3. **Automated Remédiation Pipeline (`.github/workflows/dependency-and-obsolescence-watch.yml`)**:
   - Executes weekly every Monday at 06:00 UTC or on-demand (`workflow_dispatch`).
   - Renders a rich Markdown status matrix directly to `$GITHUB_STEP_SUMMARY`.
   - Idempotently creates or updates a tracking GitHub Issue (`⚠️ [Obsolescence Watch] New Upstream Releases Available`).
   - Spawns automated Pull Requests using `peter-evans/create-pull-request@v8` on branch `chore/upstream-dependency-updates` to run the full CI test suite.

## Consequences
- **Positive**: Proactive obsolescence prevention across all layers (OS, language runtimes, CI actions, build tools).
- **Positive**: Zero manual effort required to detect new stable toolchain releases.
- **Positive**: Automated PRs ensure that every upstream upgrade is verified by rootless unit tests and Compose benchmarks before landing on `main`.
