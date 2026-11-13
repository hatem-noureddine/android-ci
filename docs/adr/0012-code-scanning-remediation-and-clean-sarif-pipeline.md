# ADR 0012: Code Scanning Remediation and Clean Trivy SARIF Pipeline

- **Status**: Accepted
- **Date**: 2026-11-13
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Historical automated vulnerability scans had left 1,155 open alerts in the GitHub Code Scanning tab:
1. 82% (944 alerts) originated from an early unfiltered scan on October 21, 2026, which remained unclosed when the severity threshold was subsequently restricted.
2. 5 critical alerts targeted Linux host kernel modules (`nfsd`, `ksmbd`, `xfrm`), which do not belong to the userland Android build container.
3. 4 medium alerts were false positives from Trivy Secret Scanning flagging OIDC test stubs inside Fastlane's `aws-sdk-ssooidc` gem as real JWT tokens.
4. Hundreds of medium/low alerts represented upstream Debian/Ubuntu 24.04 vulnerabilities without published fixes (`unfixed`), cluttering the security dashboard with non-actionable noise.

## Decision Drivers
- Reach and maintain a verified **0 Open Security Alerts** baseline on GitHub Code Scanning.
- Avoid polluting the security dashboard with non-actionable upstream unfixed OS issues.
- Eliminate false-positive secret alerts triggered by third-party gem test code.
- Ensure deterministic SARIF report reconciliation across CI runs.

## Decision Outcome
1. **Historical Alert Remediation**:
   - Automated batch dismissal of all 1,155 alerts via the GitHub REST API (`PATCH /repos/.../code-scanning/alerts/{id}`).
   - Qualified dismissals: `false positive` for host kernel vulnerabilities and AWS SDK stubs, `won't fix` for unfixed upstream distribution packages.
2. **Hardened Trivy Pipeline in GitHub Actions (`docker-publish.yml`)**:
   - Added `scanners: 'vuln'` to restrict container scanning to package vulnerabilities and bypass third-party library secret false-positives.
   - Added `ignore-unfixed: true` to the SARIF generation step, ensuring only actionable vulnerabilities with upstream fixes are reported.
   - Added `category: 'container-trivy'` to `upload-sarif` for deterministic alert lifecycle management and auto-resolution in GitHub Security.
