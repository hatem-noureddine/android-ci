# ADR 0017: Pre-Packaged Enterprise CI/CD Templates and GitLab Component Architecture

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
While `hateum/android-ci-box` provides a multi-arch, dual-mode container environment, adopting it across diverse enterprise toolchains (GitLab CI, Jenkins, Bitbucket Pipelines, GitHub Actions) required developers to manually write pipeline YAML or Groovy configurations.
Common failure modes during manual setup included:
1. Misconfigured cache directories causing Gradle cache misses across runs.
2. Incompatible UID/GID permissions on corporate runners (e.g., Jenkins running as UID 1000 encountering root-owned volume mounts).
3. Hardcoded network proxies or corporate CA workarounds that bypassed the container's built-in `entrypoint.sh` automation.
4. GitLab CI projects unable to leverage the modern GitLab 16+ Component Catalog architecture.

## Decision Drivers
- Provide drop-in, zero-friction pipeline templates for the top 4 enterprise CI/CD engines.
- Showcase the multi-stage image variant strategy (`:slim` for fast headless compilation vs `:latest` for emulator UI tests).
- Demonstrate universal UID compatibility (rootless execution with `-u 1000:1000`).
- Ensure persistent Gradle caching across jobs without unnecessary daemon overhead.

## Considered Options
1. **Inline documentation snippets only**: Fast to write, but prone to copy-paste bit-rot and untracked deprecations.
2. **Dedicated repository for CI templates**: Introduces multi-repo maintenance overhead.
3. **In-tree `ci-templates/` directory with production templates & GitLab CI Component**: Single source of truth, versioned alongside the Docker image.

## Decision Outcome
Adopted **Option 3**: In-tree `ci-templates/` directory.

### Delivered Templates:
1. **GitLab CI (`ci-templates/gitlab/.gitlab-ci.yml`)**:
   - Multi-stage pipeline (`diagnostic`, `quality`, `build`, `test_cloud`).
   - Caches `.gradle/caches/` and `.gradle/wrapper/` with SHA-keyed lockfiles.
   - Separate, parallelized `lint_and_check` and `unit_tests` stages with JUnit artifact publishing.
2. **GitLab CI Component (`ci-templates/gitlab/templates/android-ci.yml`)**:
   - Implements GitLab 16+ `spec: inputs: ...` catalog architecture.
   - Configurable parameters: `image_tag` (default: `slim`), `java_version` (`17` or `21`), `gradle_tasks`, and `cache_policy`.
3. **Jenkins (`ci-templates/jenkins/Jenkinsfile`)**:
   - Declarative pipeline using `docker { image 'hateum/android-ci-box:slim' args '-u 1000:1000 -v gradle-cache:/home/runner/.gradle' }`.
   - Native integration with Jenkins HTML Publisher and JUnit test reports.
4. **Bitbucket Pipelines (`ci-templates/bitbucket/bitbucket-pipelines.yml`)**:
   - Reusable step anchors (`&diagnostics`, `&lint-and-test`, `&assemble-release`).
   - Custom cache definitions for `/home/runner/.gradle/caches`.
5. **GitHub Actions (`ci-templates/github/android-ci-workflow.yml`)**:
   - Reusable `workflow_call` workflow easily consumable across any GitHub organization.

## Consequences
- **Positive**: Developers can copy and paste production-tested CI configurations that properly leverage image caching and rootless permissions.
- **Positive**: Teams save hours of pipeline debugging.
- **Negative**: Templates must be periodically tested when upstream CI engines deprecate syntax.
