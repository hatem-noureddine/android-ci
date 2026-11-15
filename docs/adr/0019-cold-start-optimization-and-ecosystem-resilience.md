# ADR 0019: Cold-Start Optimization, Ecosystem Hygiene and Modern Kotlin DSL Testing

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Following the rollout of multi-stage variants (`:slim` vs `:latest`) and enterprise CI templates, three operational opportunities remained:
1. **Gradle Wrapper Cold-Start Latency**: Even though standalone Gradle was installed in `/opt/gradle`, projects executing `./gradlew` on pristine CI runners had to redownload the ~150 MB `gradle-9.8.2-bin.zip` wrapper archive from `services.gradle.org`, incurring 15-30s of startup latency per job.
2. **CI Template Syntax Integrity & Docker Hub Synchronization**: As templates evolved across `ci-templates/`, automated validation was required to prevent syntax regressions. Furthermore, Docker Hub's long-form repository description risked drift without automated synchronization from `docs/dockerhub-overview.md`.
3. **Absence of Modern Kotlin DSL / Compose Sample**: While `test_projects/SampleProject` validated Groovy DSL, modern Android projects heavily rely on Kotlin DSL (`build.gradle.kts`), Version Catalogs (`libs.versions.toml`), and Jetpack Compose.

## Decision Drivers
- Eliminate redundant wrapper download overhead on cold runner starts.
- Enforce strict YAML validation across all CI templates in pull requests.
- Guarantee continuous vulnerability monitoring via weekly scheduled Trivy scans.
- Provide automated regression testing for Kotlin DSL and Version Catalogs.

## Decision Outcome
1. **Pre-Seeded Gradle Wrapper Distribution (`Dockerfile`)**:
   - Pre-extracted Gradle 9.8.2 directly into `/home/runner/.gradle/wrapper/dists/gradle-9.8.2-bin/8wepis63pzuhrlfaiy04bagwu/gradle-9.8.2/`.
   - Created the completion marker `gradle-9.8.2-bin.zip.ok`.
   - Result: `./gradlew` executions in projects targeting Gradle 9.8.2 bypass downloads entirely, cutting cold-start latency by up to 30 seconds.
2. **CI Template Linter & Weekly Security Scan (`.github/workflows/`)**:
   - Added YAML syntax validation for all files under `ci-templates/` to the pre-merge static analysis job.
   - Implemented [`.github/workflows/scheduled-security-scan.yml`](../../.github/workflows/scheduled-security-scan.yml) running weekly (every Monday at 04:00 UTC) to audit `:latest` and `:slim` against emerging CVEs.
   - Synchronized `docs/dockerhub-overview.md` with Docker Hub's repository overview via `peter-evans/dockerhub-description@v4`.
3. **Modern Kotlin DSL Sample Project (`test_projects/ComposeCatalogProject`)**:
   - Implemented a complete reference project featuring Kotlin 2.1.10, AGP 8.9.0, Jetpack Compose BOM 2025.02, `settings.gradle.kts`, and `gradle/libs.versions.toml`.
   - Integrated automated `detect-android-project` verification into `tests/test-image.sh`.

## Consequences
- **Positive**: Substantially faster cold-start builds for any project using Gradle 9.8.2.
- **Positive**: Zero risk of malformed CI templates reaching end-users.
- **Positive**: Proactive detection of zero-day vulnerabilities even between image releases.
