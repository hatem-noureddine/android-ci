# ADR 0021: Production Hardening, Dynamic Cgroup Memory Tuning and KPI Pre-flight Gate

- **Status**: Accepted
- **Date**: 2026-11-15
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
When running in production CI/CD platforms (Kubernetes, OpenShift, GitLab Runner, Bitbucket Pipelines, and Jenkins agents), three operational hazards impact reliability:
1. **Silent OOMKills (`Exit Code 137`)**: Hardcoded JVM heap parameters (e.g. `-Xmx4g`) trigger immediate kernel termination when executed inside pods with constrained memory quotas (e.g., 3.5 GB or 4 GB limits), because Metaspace, JNI, and OS buffers exceed the cgroup limit.
2. **Absence of Pre-Flight Quality & Resource Gates**: Pipelines frequently fail several minutes into a build due to insufficient disk space or restricted workspace permissions that could have been verified upfront in milliseconds.
3. **Lack of Automated Performance Regression Tracking**: Teams lacked direct visibility into cold-start vs. warm build speedups and regression boundaries in CI summary dashboards.

## Decision Drivers
- Guarantee zero OOMKills across any container memory boundary (from 2 GB pods to 64 GB bare-metal nodes).
- Deliver an instant (< 100ms) pre-flight diagnostic gate with strict binary exit codes (`0` for success, `1` for failure).
- Enforce hard automated performance regression limits on cold-start and cached compilation.
- Surface continuous benchmark metrics and production KPIs directly within GitHub Step Summaries.

## Decision Outcome
1. **Dynamic Cgroup Memory Tuning Engine (`entrypoint.sh`)**:
   - Implemented dynamic detection of container memory limits using:
     - **Cgroups v2**: `/sys/fs/cgroup/memory.max`
     - **Cgroups v1**: `/sys/fs/cgroup/memory/memory.limit_in_bytes`
     - Fallback to host `/proc/meminfo` when cgroups are unbounded.
   - Automatically computes Gradle JVM heap (`-Xmx`) as **70% of available container RAM**:
     - Constrained at a minimum floor of 1536 MB (1.5 GB).
     - Capped at a maximum ceiling of 8192 MB (8 GB) to reserve headroom for native Kotlin compiler daemons, Metaspace, and OS buffers.
   - User overrides via `GRADLE_JVMARGS` continue to take full precedence.
2. **Production Pre-Flight Gate (`ci-doctor --kpi-check`)**:
   - Added `ci-doctor --kpi-check`, executing in under 100ms:
     - **Memory Quota**: Fails if < 1500 MB; warns if < 3000 MB.
     - **Disk Space**: Fails if < 2000 MB free on `/project`; warns if < 5000 MB.
     - **Workspace Permissions**: Validates rootless universal write access on `/project`, `/home/runner/.gradle`, `/certificates`, and `/home/runner/.android/avd`.
     - **Toolchain & Connectivity**: Validates Java, Gradle, SDK components, and repository reachability.
   - Returns exit code `0` on optimal health, or `1` on critical failure.
   - Enriched `ci-doctor --json` with a dedicated `resources` object.
3. **Continuous Benchmarking & CI Step Summary Dashboard (`tests/test-image.sh` & `.github/workflows/docker-publish.yml`)**:
   - Instruments Test 6b to export a structured `build/benchmarks.json` artifact recording cold-start duration, warm build duration, and cache speedup.
   - Asserts non-regression boundaries: fails if cold-start > 180s or cached build > 35s.
   - Publishes an executive Quality & Performance Dashboard directly into `$GITHUB_STEP_SUMMARY`.

## Consequences
- **Positive**: Eliminates silent OOMKill failures in restricted Kubernetes and enterprise cloud runners.
- **Positive**: Instant pre-flight diagnostic catching quota and permission bottlenecks before Gradle initializes.
- **Positive**: Continuous performance transparency and regression prevention on every release.
