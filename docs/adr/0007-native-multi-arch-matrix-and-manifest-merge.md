# ADR 0007: Distributed Multi-Arch Build Matrix and Manifest Merging

- **Status**: Accepted
- **Date**: 2026-11-06
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Previously, multi-architecture image releases (`linux/amd64` and `linux/arm64`) were executed within a single `docker/build-push-action` step on an `x86_64` GitHub-hosted runner using QEMU user-space software emulation.
Because C compilation (such as building Ruby 4.0 and native C gem extensions) incurs a 15x–20x performance penalty under QEMU emulation, the release workflow duration exploded to **over 1 hour and 17 minutes**.

## Decision Drivers
- Drastically cut pipeline execution time (target < 10 minutes total release duration).
- Eliminate slow QEMU CPU emulation for ARM64 builds.
- Seamless multi-registry publishing to both Docker Hub and GitHub Container Registry (GHCR).
- Zero user-facing changes: consumers still pull multi-arch `hateum/android-ci-box:latest` or SemVer tags seamlessly.

## Considered Options
1. **Single Runner with QEMU**: Build both platforms in one step. (Rejected: >1h15m build time).
2. **Native Parallel Matrix + Manifest Merge (`docker buildx imagetools create`)**: Build `linux/amd64` on `ubuntu-24.04` and `linux/arm64` on official GitHub `ubuntu-24.04-arm` runners simultaneously, push architecture-tagged images, then merge them in a lightweight final job.

## Decision Outcome
Chosen option: **Option 2 (Parallel Matrix + Manifest Merge)**, because:
1. **Full Hardware Speed**: Both architectures compile natively on multi-core ARM64 and x86_64 silicon without QEMU translation overhead.
2. **Parallel Concurrency**: Building simultaneously cuts the build phase duration from 75+ minutes to ~5 minutes.
3. **Instant Manifest Assembly**: `docker buildx imagetools create` merges the images into standard multi-architecture OCI manifest lists in seconds without recompilation.
4. **Resilience & Tagging**: In addition to standard multi-arch tags (`latest`, `1.3.1`, `1.3`, `1`), architecture-specific tags (`1.3.1-amd64` and `1.3.1-arm64`) are made available for deterministic deployment environments.
