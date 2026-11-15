# ADR 0020: Native Multi-Architecture Validation, Jetpack Compose End-to-End Testing and Performance Benchmarks

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
While the repository previously produced multi-architecture Docker manifests (`linux/amd64` and `linux/arm64`), validation remained asymmetric:
1. **Asymmetric Architecture Validation**: Full container validation via `tests/test-image.sh` was previously executed only during the pre-build testing phase on an `x86_64` runner (`ubuntu-24.04`). The native `arm64` image built on GitHub's native `ubuntu-24.04-arm` runners was not tested end-to-end prior to manifest aggregation and publishing.
2. **Missing End-to-End Modern Compose & Kotlin DSL Pipeline**: While `test_projects/ComposeCatalogProject` was introduced in ADR-0019 to validate `detect-android-project`, it was not yet compiled and tested through `tests/test-image.sh`.
3. **Absence of Quantitative Cache & Cold-Start Benchmarks**: CI logs lacked concrete timing measurements demonstrating the performance benefits of wrapper pre-seeding and Gradle build caching.

## Decision Drivers
- Guarantee that both `amd64` and `arm64` container images pass the entire 12-stage validation suite on actual hardware before publication.
- Ensure end-to-end compilation, unit testing, and APK generation for modern Kotlin DSL (`.kts`), Version Catalogs (`libs.versions.toml`), and Jetpack Compose.
- Provide transparent build cache benchmarking in test logs (cold-start vs. warm cached build speedup).
- Prevent architecture-specific runtime failures on Apple Silicon and AWS Graviton CI runners.

## Decision Outcome
1. **Native Multi-Architecture In-Pipeline Verification (`.github/workflows/docker-publish.yml`)**:
   - Added a `Native Architecture Test Suite Verification (${{ matrix.arch }})` step to the matrix build job on `ubuntu-24.04` (`amd64`) and `ubuntu-24.04-arm` (`arm64`).
   - The runner pulls its native single-architecture image slice directly from GHCR (`ghcr.io/hatem-noureddine/android-ci-box:${VERSION}-slim-${matrix.arch}`) and runs `/project/tests/test-image.sh`.
   - Manifest creation in Job 4 only proceeds if both native test suites exit with code 0.
2. **End-to-End Jetpack Compose Build & Test Step (`tests/test-image.sh` - Test 6b)**:
   - Added automated compilation and testing of `test_projects/ComposeCatalogProject`:
     - Runs `./gradlew test assembleDebug --no-daemon --build-cache`.
     - Asserts successful generation of `app/build/outputs/apk/debug/app-debug.apk`.
3. **Build Cache & Cold-Start Performance Benchmarking**:
   - Integrated epoch-based duration timers into Test 6b.
   - Measures cold-start compilation duration alongside warm cached build duration, logging the speedup metric directly in CI execution output.

## Consequences
- **Positive**: 100% test coverage across both `amd64` and `arm64` architectures on physical bare-metal/virtualized hardware before release.
- **Positive**: Immediate detection of Kotlin/Compose compiler incompatibilities or architecture-specific JNI/NDK regressions.
- **Positive**: Transparent verification of build-cache efficiency in CI diagnostics.
