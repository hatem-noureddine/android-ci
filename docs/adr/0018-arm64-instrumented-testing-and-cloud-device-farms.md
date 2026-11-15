# ADR 0018: ARM64 Instrumented Testing Strategy and Cloud Device Farm Delegation

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
A fundamental limitation of modern Android CI tooling on Linux is that **Google publishes the Linux Android SDK Emulator package (`emulator`) exclusively for `x86_64` (`amd64`)**.
On `linux/arm64` hosts (such as AWS Graviton `c7g`, Apple Silicon runner nodes, Oracle Cloud Ampere A1, or Google Cloud Tau T2A), Google's SDK repositories do not provide an emulator package.

However, enterprise development teams are aggressively migrating CI infrastructure to ARM64 due to:
- 20-40% lower compute cost.
- Native instruction parity when building Android ARM64 APKs.
- Superior unit test and compilation throughput.

Teams running on ARM64 CI runners require a clear, production-tested architecture for running instrumented UI tests without abandoning ARM64 infrastructure.

## Decision Drivers
- Clarify architectural boundaries between `amd64` and `arm64` capabilities.
- Provide practical, automated solutions for executing instrumented UI tests from ARM64 runners.
- Document cloud device farm delegation (Firebase Test Lab, AWS Device Farm) as first-class citizens.
- Prevent pipeline failures caused by attempting to spawn unavailable emulators on ARM64.

## Considered Strategies

### Strategy 1: Architectural Split-Runner CI Matrix (Recommended for Hybrid Fleets)
- Execute compilation, linting, static analysis, unit tests, and APK/AAB release packaging on fast, cost-effective **ARM64 runners** using `hateum/android-ci-box:slim`.
- Dispatch instrumented UI tests conditionally to a dedicated **`amd64` runner** equipped with `/dev/kvm` hardware virtualization using `hateum/android-ci-box:latest`.

### Strategy 2: Cloud Device Farm Delegation (Recommended for Pure Cloud / Pure ARM64)
- Run the build on the ARM64 runner to generate the application APK and androidTest APK:
  `./gradlew assembleDebug assembleDebugAndroidTest`
- Delegate the test execution to cloud hardware farms:
  - **Google Firebase Test Lab**: Execute tests across real physical devices (Pixel, Samsung) or virtual devices via `gcloud firebase test android run`.
  - **AWS Device Farm**: Upload APKs via AWS CLI or Fastlane plugin.
- **Benefits**: Zero virtualization overhead on CI runners, real physical hardware testing, zero emulator maintenance.

### Strategy 3: Native ARM64 Android Virtualization (Cuttlefish / Redroid)
- On bare-metal ARM64 cloud instances with KVM enabled (e.g. AWS `c7g.metal`, Oracle A1.Flex), run AOSP Cuttlefish or Redroid containers.
- **Benefits**: Native ARM instruction execution without instruction emulation.
- **Trade-off**: Requires bare-metal instances with nested virtualization access, not available on standard shared cloud VMs.

## Decision Outcome
1. Formalize the **Split-Runner Matrix** and **Cloud Device Farm Delegation** as the official architectural patterns for ARM64 Android CI.
2. Provide [`bin/run-firebase-testlab`](../../bin/run-firebase-testlab), a battle-tested helper CLI that automates packaging and running tests on Firebase Test Lab from any CI runner.
3. Update project documentation (`README.md`, `docs/index.html`, and `.agents/skills/android-ci-box/SKILL.md`) to guide developers through ARM64 vs amd64 capabilities.

## Consequences
- **Positive**: Eliminates confusion regarding emulator availability on Linux ARM64.
- **Positive**: Enables enterprises to cut CI costs with ARM64 while maintaining 100% test coverage.
- **Positive**: Turnkey automation via `run-firebase-testlab`.
