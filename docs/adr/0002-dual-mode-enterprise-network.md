# ADR 0002: Dual-Mode Universal Network Engine Architecture

- **Status**: Accepted
- **Date**: 2026-10-21
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Android CI pipelines run across vastly different environments: clean public cloud runners (GitHub Actions, GitLab SaaS) and locked-down corporate intranets featuring SSL inspection (Zscaler, Netskope), HTTP proxies, and internal repository mirrors (Nexus, Artifactory). Traditional images require manual Dockerfile edits or complex CI scripts to inject certificates and proxy settings.

## Decision Drivers
- Zero configuration required for public open-source builds.
- Seamless, automated configuration when corporate environment variables are passed.
- Robust handling of Java truststore (`cacerts`) and Gradle system properties (`systemProp.http.*`).

## Decision Outcome
Chosen option: **Runtime Auto-Detection Engine via `entrypoint.sh`**.
1. **Public Mode**: Default operation without proxy or mirror variables uses direct official Google Maven and Maven Central connections.
2. **Enterprise Mode**: If `CORPORATE_CA_URL` or `/certificates/*.crt` is present, certificates are automatically imported into `/usr/local/share/ca-certificates` and Java `cacerts`. If `HTTP_PROXY` or `NEXUS_URL` is set, `gradle.properties` and Gradle init scripts are synthesized automatically on container boot.

## Consequences
- **Positive**: Single universal image works identically on local dev machines, public GitHub runners, and restricted banking/enterprise infrastructures.
- **Negative**: Entrypoint executes slight initialization overhead (~100ms) on container boot.
