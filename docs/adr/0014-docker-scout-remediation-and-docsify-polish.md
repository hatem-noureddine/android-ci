# ADR 0014: Docker Scout Vulnerability Remediation and Documentation Polish

- **Status**: Accepted
- **Date**: 2026-11-14
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Following the release of v1.4.7 and the deployment of GitHub Pages:
1. Docker Scout reported **8 Critical vulnerabilities** on the published multi-arch image:
   - 6 Critical CVEs in Go `stdlib 1.22.2` (originating from Ubuntu's outdated `git-lfs 3.4.1` package).
   - 2 Critical CVEs in BouncyCastle `bcprov-jdk18on 1.79` (originating from Google's bundled `cmdline-tools`).
2. Docker Scout also flagged several High vulnerabilities:
   - Python build tools (`wheel 0.42.0`, `setuptools 68.1.2`, `pip 24.0`).
   - Guava (`guava 33.4.0-jre`) in `cmdline-tools`.
   - `protobuf-java 2.6.1` and `jline 3.24.1` inside `lint-psi` (standalone lint CLI).
   - Ruby default gem specification `json 2.18.0`.
3. The newly launched Docsify documentation on GitHub Pages suffered from:
   - Incompatible styling between `vue.css` and `docsify-darklight-theme` causing visual glitches in dark mode.
   - Heavy redundancy between `docs/README.md` and root `README.md`.
   - Broken internal links pointing to relative directories outside `/docs` (causing 404s inside Docsify).
   - Unwanted "Governance & Decisions" section in navigation.

## Decision Drivers
- Eradicate all 8 Critical CVEs and fixable High CVEs identified by Docker Scout.
- Provide a clean, modern, glitch-free documentation interface on GitHub Pages via Docsify Themeable.
- Remove content redundancies, broken internal anchors, and unwanted navigation categories.
- Ensure strict zero-warning compliance on ShellCheck and Hadolint.

## Decision Outcome
1. **Docker Scout Vulnerability Eradication (`Dockerfile`)**:
   - Replaced Ubuntu's apt `git-lfs` package with the official static release **Git-LFS v3.8.1** across `amd64` and `arm64`, eliminating all 6 Critical Go stdlib CVEs.
   - Upgraded Python packages (`pip`, `setuptools`, `wheel`) via `python3 -m pip install --upgrade` and purged obsolete `.dist-info` directories.
   - Performed in-place upgrades of `bcprov-jdk18on` and `bcpkix-jdk18on` to version **1.87** in `${ANDROID_HOME}/cmdline-tools/latest/lib/external/org/bouncycastle/`, eliminating the 2 Critical BouncyCastle CVEs.
   - Upgraded `guava` to **33.8.0-jre** in `cmdline-tools`.
   - Purged `${ANDROID_HOME}/cmdline-tools/latest/lib/external/lint-psi` (unused in CI pipelines).
   - Installed `json 3.1.0` gem and purged the obsolete default specification `json-2.18.0.gemspec`.
2. **Docsify Themeable & Documentation Polish (`docs/`)**:
   - Switched to **Docsify Themeable** (`theme-simple.css`) with clean system typography and responsive Google Blue branding (`#1a73e8`).
   - Completely purged the "Governance & Decisions" section from `_sidebar.md`.
   - Streamlined `docs/README.md` with visual access cards pointing to the 3 core pillars (Architecture, CI/CD, AI Agents), eliminating duplicate comparison tables.
   - Replaced all external relative file links with canonical GitHub URLs to ensure zero 404 errors.
