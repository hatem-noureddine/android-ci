# ADR 0011: Runtime Robustness, Dynamic Diagnostics, and Test Hardening

- **Status**: Accepted
- **Date**: 2026-11-13
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Following the comprehensive container audit, several runtime edge cases and diagnostic limitations required hardening:
1. `ci-doctor` hardcoded Bundletool version to `1.18.3` instead of reporting runtime state dynamically, and executed `gradle -version` (spawning a background daemon) during Docker healthchecks every 30 seconds.
2. In `entrypoint.sh`, HTTP proxy parsing with naive `cut -d: -f1` failed if URLs included basic auth credentials (`user:pass@host:port`) or custom ports, and mounting an existing `gradle.properties` volume silently skipped CI defaults without user awareness.
3. In `bin/install-ndk-version`, the default symlink was not updated if a symlink already existed.
4. Test suites lacked explicit verification for `OFFLINE_MODE=false`, rbenv shims, and healthcheck `java_home` integrity.

## Decision Drivers
- Zero daemon overhead during periodic Docker healthchecks.
- Accurate, dynamically discovered tooling versions.
- Resilient network parsing supporting complex enterprise proxy setups.
- Thorough test assertions eliminating silent false-positives.

## Decision Outcome
1. **Dynamic Diagnostics & Lightweight Healthchecks**:
   - `ci-doctor` discovers Gradle version directly from `/opt/gradle/gradle-*` directory metadata in milliseconds without launching a JVM process or daemon.
   - Dynamic `bundletool version` discovery replaces hardcoded strings.
   - Robust `clean_token()` sanitization strips stray whitespace, newlines, and carriage returns from JSON outputs.
2. **Enterprise Proxy & Runtime Resilience**:
   - Integrated Python-based URL parsing in `entrypoint.sh` correctly resolves host, port, and credentials across all proxy schemes (`http://`, `https://`, basic auth).
   - Added transparent log notice when a mounted `gradle.properties` file is detected.
   - Sanitized NDK default symlink creation so it always points to the active/most recently installed NDK version.
3. **Hardened Test Assertions**:
   - Added explicit verification for `OFFLINE_MODE=false`.
   - Verified that active `ruby` in PATH points to the rbenv shim.
   - Added strict assertions on `java_home` within the `ci-doctor --json` report.
