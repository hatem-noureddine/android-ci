# ADR 0010: Security Hardening, Groovy Injection Sanitization, and Safe CA Bootstrap

- **Status**: Accepted
- **Date**: 2026-11-13
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Container audit findings highlighted potential security vectors:
1. Shell variables passed to Gradle `.init.gradle` Groovy scripts (`NEXUS_URL`, `NEXUS_USER`, `NEXUS_PASSWORD`, `GRADLE_BUILD_CACHE_URL`) were interpolated using unescaped single quotes (`'...'`), allowing accidental syntax corruption or Groovy code injection if credentials contained special characters (`'`, `\`, `$`).
2. Corporate CA certificates downloaded via `CORPORATE_CA_URL` systematically used `curl -k` (bypassing SSL verification), exposing the container to MITM poisoning during truststore bootstrap.
3. Universal `chmod 777 /opt` opened the entire `/opt` directory to deletion or tampering by arbitrary container processes.

## Decision Drivers
- Zero vulnerabilities and strict defense-in-depth security.
- Preserve rootless container compatibility across arbitrary UIDs (e.g. OpenShift, GitLab Runner, GitHub Actions).
- Prevent accidental or malicious Groovy code injection from environment variables.
- Maintain seamless developer experience while requiring explicit opt-in for insecure TLS bypasses.

## Decision Outcome
1. **Groovy String Sanitization**:
   - Added `escape_groovy_single_quotes()` helper in `entrypoint.sh` to safely sanitize backslashes, single quotes, and dollar signs (`\`, `'`, `$`) before generating `nexus-mirror.init.gradle` and `remote-build-cache.init.gradle`.
   - Verified via integration tests in `tests/test-image.sh`.
2. **Safe Corporate CA Bootstrap**:
   - `curl -fsSL` without `-k` is now the default for downloading `CORPORATE_CA_URL`.
   - Insecure TLS bypass requires explicit user consent via `INSECURE_CA_DOWNLOAD=true` or `ALLOW_INSECURE_CA=true`.
3. **Hardened `/opt` Permissions**:
   - Replaced world-writable `chmod 777 /opt` with standard POSIX Sticky Bit `chmod 1777 /opt` (similar to `/tmp`), ensuring non-root users can write without being able to delete or rename root-owned directories.
   - Dedicated `chmod 777 /opt/default-jdk` preserves rootless JDK toggling via `switch-jdk`.
