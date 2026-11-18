# ADR 0024: Turnkey Built-In Fastlane Lanes (`ci-lane`) and Commercial B2B Monetization Architecture

- **Status**: Accepted
- **Date**: 2026-11-18
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Integrating Android CI/CD pipelines historically requires mobile engineering teams to write and maintain extensive boilerplate:
1. **Fastfile Redundancy**: Developers repeatedly craft identical Fastlane lanes across projects for linting, running unit tests, generating signed release bundles, badging icons, and publishing to stores (Firebase App Distribution, Google Play Store).
2. **Setup Friction**: In GitLab CI, GitHub Actions, and Bitrise, teams without dedicated Mobile DevOps engineers struggle with keystore decoding, report extraction, and ChatOps webhook payloads.
3. **Monetization & Sustainability**: While `hateum/android-ci-box` provides enterprise-grade performance and security, maintaining it requires dedicated development effort. Sustainable monetization pathways (sponsorships, specialized consulting) were previously missing.
4. **Professional Positioning**: The maintainer is a Senior Android Engineer & Mobile Release Specialist (not a DevOps/sysadmin). Commercial offerings must focus squarely on high-value Android engineering challenges (Gradle build optimization, eliminating `OOMKilled` exit code 137, AGP 9 migration, and automated store delivery).
5. **Privacy & Security Constraints**: The maintainer's personal email must remain protected and never be harvested from public source repositories or HTML documentation.

## Decision Drivers
- **Zero-Boilerplate Turnkey Execution**: Enable 1-line CI/CD pipeline definitions (`ci-lane all`, `ci-lane test`) without requiring any `Fastfile` in user repositories.
- **Graceful Extensibility**: Respect user-defined `fastlane/Fastfile` or `Fastfile` if present in the workspace, while defaulting to the container's built-in engine.
- **Deep Customization via Standard Environment Variables**: Allow customization of icon badges (`BADGE_TEXT`, `BADGE_COLOR`), signing keys, store credentials, and multi-channel notification webhooks.
- **Sustainable Commercial Architecture**: Introduce community sponsorship via GitHub Sponsors and high-ticket B2B consulting services.
- **Secure Communication Channel**: Utilize a secure interactive contact form (Formspree endpoint) with zero exposed email addresses.

## Decision Outcome
1. **Universal Built-In Fastfile (`/opt/fastlane/Fastfile`)**:
   - Authored `fastlane/Fastfile.builtin` and packaged it at `/opt/fastlane/Fastfile` with rootless universal read/write permissions (`777`).
   - Implemented a complete lane catalog:
     - **Quality & Verification**: `test`, `lint`, `detekt`, `sonar`, `screenshot_tests`.
     - **Compilation & Packaging**: `build_debug`, `build_release`, `bundle`, `clean`.
     - **Dynamic Icon Badging**: `badge` (using Python PIL for fast, lightweight banner and shield generation over launcher icons).
     - **Code Signing**: `sign` (base64 keystore decoding and Gradle property injection).
     - **Store Distribution**: `distribute_firebase`, `distribute_playstore`, `distribute_github`.
     - **ChatOps Notifications**: `notify_slack`, `notify_teams`, `notify` (multi-channel broadcast).
     - **End-to-End Orchestrator**: `all` (clean -> lint -> test -> badge -> build -> distribute -> notify).

2. **Turnkey CLI Router (`/usr/local/bin/ci-lane`)**:
   - Packaged a portable, POSIX-compliant Bash utility (`ci-lane`).
   - Automatically checks for local `fastlane/Fastfile` or `Fastfile`. If absent, seamlessly exports `FASTLANE_FASTFILE=/opt/fastlane/Fastfile` and dispatches execution through Bundler.
   - Includes built-in `list` and `help` commands for developer introspection.

3. **Community Sponsorship Engine (`.github/FUNDING.yml`)**:
   - Activated GitHub Sponsors for `hatem-noureddine`.
   - Linked custom sponsorship inquiries to the documentation portal.

4. **B2B Commercial Consulting Portal**:
   - Positioned the maintainer as a **Senior Android Engineer & Mobile Release Specialist**.
   - Formulated 4 focused, high-impact offerings:
     1. *Turnkey Mobile CI/CD Pipeline Setup* (GitHub Actions, GitLab CI, Bitrise).
     2. *Gradle Build Optimization & OOMKill Remediation* (40-70% build speedups, remote cache, daemon tuning).
     3. *Automated Store Releases & Fastlane Orchestration* (zero-touch store deployments).
     4. *Modern Android Architecture & AGP 9 Migration* (AGP 8/9, Kotlin Multiplatform, Gradle Managed Devices).
   - Embedded an interactive inquiry form in `docs/index.html` communicating via Formspree (`https://formspree.io/f/mqaeapzy`) without exposing personal contact details.

5. **Semantic Versioning & Tooling Alignment**:
   - Version incremented to `v1.7.0`.
   - Updated AI Agent Skill (`SKILL.md`) to guide autonomous agents in invoking `ci-lane`.
   - Published comprehensive user documentation in `docs/ci-lane.md`.

## Consequences
- **Positive**: Developers can spin up complete CI/CD pipelines in GitLab CI, GitHub Actions, or Bitrise in under 2 minutes with 1 line of configuration.
- **Positive**: Projects retain full freedom to supply their own `Fastfile` without conflict.
- **Positive**: Clear commercial monetization path establishes financial sustainability for continued open-source development.
- **Positive**: Zero personal data exposure while maintaining a seamless enterprise lead-capture mechanism.
