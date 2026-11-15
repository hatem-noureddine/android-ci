# ADR 0022: GitHub Actions Node 24 Migration, Python Toolchain Security Upgrades and Comprehensive Trivy SARIF Remediation

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Following the release of `v1.6.3`, two operational hygiene and security requirements were identified:
1. **GitHub Actions Node 20 Runtime Deprecation**: GitHub announced that runner runtimes are transitioning from Node.js 20 to Node.js 24. Actions referencing older major tags (`docker/setup-qemu-action@v3`, `peter-evans/dockerhub-description@v4.0.0`, and `anchore/sbom-action/download-syft@v0.18.0`) emitted deprecation warnings during pipeline execution.
2. **Trivy SARIF Security Findings (26 Alerts)**: Automated container scans uploaded to GitHub Code Scanning surfaced 26 alerts across three distinct source categories:
   - Python ecosystem dependencies (`wheel`, `setuptools`, `pip`, `jaraco.context`).
   - Bundled Go dependencies within the static `git-lfs` 3.8.1 binary.
   - Bundled internal `guava` JAR within the Gradle 9.8.2 binary distribution.

## Decision Drivers
- Guarantee 100% deprecation-free pipeline execution under GitHub Actions Node 24.
- Eliminate fixable vulnerabilities in the container base layer by updating Python core utilities (`pip`, `setuptools`, `wheel`) to modern patched releases.
- Formally document and triage upstream third-party bundled dependencies in `.trivyignore` in strict compliance with `AGENTS.md`.
- Ensure clean SARIF report generation across all scheduled and on-demand security scans.

## Decision Outcome
1. **GitHub Actions Node 24 Full Migration**:
   - Upgraded `docker/setup-qemu-action` from `@v3` to `@v4` (native Node 24 support).
   - Upgraded `peter-evans/dockerhub-description` from `@v4.0.0` to `@v5` (native Node 24 support).
   - Upgraded `anchore/sbom-action/download-syft` to `@v0` tracking the latest Node 24 compatible releases.
   - Enforced `ACTIONS_RUNNER_FORCE_NODE24: "true"` across all workflow definitions (`docker-publish.yml`, `scheduled-security-scan.yml`, and `dockerhub-sync-description.yml`).
2. **Python Toolchain Base Layer Hardening**:
   - Upgraded Python build arguments in `Dockerfile`:
     - `PIP_VERSION`: `25.0.1` ➔ `26.3` (resolves CVE-2026-1703, CVE-2026-8643, CVE-2026-6357, CVE-2026-3219, CVE-2026-13346, CVE-2025-8869).
     - `SETUPTOOLS_VERSION`: `75.8.0` ➔ `84.2.1` (resolves GHSA-xmj3-9gf7-h52w, CVE-2026-59890, CVE-2025-47273, and vendored jaraco.context CVE-2026-23949).
     - `WHEEL_VERSION`: `0.45.1` ➔ `0.48.0` (resolves CVE-2026-24049).
3. **Upstream Bundled Dependency Governance (`.trivyignore`)**:
   - Documented and triaged 13 CVEs originating from upstream Go libraries statically compiled inside the official `git-lfs` 3.8.1 release (`golang.org/x/net`, `golang.org/x/crypto`, `golang.org/x/text`). These internal network/SSH routines are not exposed in container CI execution.
   - Documented `CVE-2026-102554` regarding internal `guava` packaged inside the standalone Gradle 9.8.2 binary distribution.
   - Configured `scheduled-security-scan.yml` with `ignore-unfixed: true` and `trivyignores: '.trivyignore'` to ensure parity with the primary release pipeline.

## Consequences
- **Positive**: 0 Node.js 20 deprecation warnings on GitHub Actions runners.
- **Positive**: Upstream Python toolchain updated to latest vulnerability-free releases.
- **Positive**: GitHub Code Scanning alerts remediated and properly governed.
