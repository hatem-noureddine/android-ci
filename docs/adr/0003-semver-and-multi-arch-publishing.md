# ADR 0003: Semantic Versioning and Multi-Architecture Publishing

- **Status**: Accepted
- **Date**: 2026-10-21
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Images originally used technical tags (e.g., `api37`, `gradle9`). This prevented deterministic reproducibility, made rollback difficult, and conflicted with standard SemVer enterprise delivery practices. Additionally, modern CI runners operate across both `x86_64` (`amd64`) and ARM64 (`arm64` - AWS Graviton, Apple Silicon).

## Decision Drivers
- Strict reproducibility and immutability for enterprise releases.
- Compatibility with standard SemVer (`MAJOR.MINOR.PATCH`).
- Automated multi-architecture image publication (`linux/amd64`, `linux/arm64`).

## Decision Outcome
Chosen option: **File-based SemVer (`VERSION`) + Multi-Arch Buildx + Dual Registry (Docker Hub & GHCR)**.
1. The root `VERSION` file is the single source of truth.
2. Push to `main` derives:
   - `latest`: Current default stable.
   - `X.Y.Z`: Exact SemVer release.
   - `X.Y`: Minor floating alias.
   - `X`: Major floating alias.
   - `sha-<hash>`: Short commit SHA for immutable auditability.
3. Automated GitHub Release (`vX.Y.Z`) is published simultaneously.
4. Images are published concurrently to Docker Hub (`hateum/android-ci-box`) and GitHub Container Registry (`ghcr.io/hatem-noureddine/android-ci-box`).
