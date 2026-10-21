# ADR 0005: Migration to Official Google Android CLI (`android`)

- **Status**: Accepted
- **Date**: 2026-10-21
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Google officially deprecated `sdkmanager` and announced its progressive phase-out in favor of the new unified **`android` CLI** (`cmdline-tools/latest/bin/android`). Early builds of `sdkmanager` issue deprecation warnings:
`WARNING: The SDK Manager CLI tool (sdkmanager) is deprecated. Use Android CLI instead. The 'android' binary can also be found in the cmdline-tools directory, and 'android sdk' is the replacement for 'sdkmanager'.`

## Decision Drivers
- Avoid future pipeline breakages when Google eventually removes `sdkmanager`.
- Adopt Google's recommended modern tooling standards for 2026+.
- Maintain 100% backward compatibility for legacy third-party Gradle plugins and CI scripts.

## Decision Outcome
Chosen option: **Dual Support with Android CLI Priority**.
1. Helper script `bin/install-sdk-version` attempts `android sdk install "$pkg"` first; if unavailable, it falls back to `sdkmanager "$pkg"`.
2. Diagnostic utility `ci-doctor` checks and reports `Android CLI` presence and version.
3. Test suite `tests/test-image.sh` verifies `android --version`.
4. `sdkmanager` and `avdmanager` are preserved in `$PATH` to ensure no third-party Gradle tasks break.
