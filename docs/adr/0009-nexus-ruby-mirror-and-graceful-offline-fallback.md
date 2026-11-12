# ADR 0009: Enterprise Ruby/Fastlane Nexus Mirror and Graceful Offline Fallback

- **Status**: Accepted
- **Date**: 2026-11-12
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Enterprise CI/CD environments frequently operate behind strict air-gapped perimeters or corporate firewalls. In such environments:
1. Android Gradle builds fetch dependencies through an internal Sonatype Nexus or JFrog Artifactory mirror (`NEXUS_URL`).
2. Fastlane pipelines fetch Ruby gems via an internal RubyGems proxy in Nexus. If Bundler and RubyGems attempt to connect to public `https://rubygems.org`, builds stall or crash.
3. During intermittent corporate network outages or in fully air-gapped runs (`--network none`), pipelines failing on long connection timeouts lead to wasted runner compute and frustrating failures, even when all required artifacts exist in local Gradle and Bundler caches.

## Decision Drivers
- Support private enterprise RubyGems mirrors via `NEXUS_RUBY_URL`.
- Default to public `rubygems.org` seamlessly when no mirror is specified.
- Prevent pipeline hangs and crashes during network outages by automatically degrading to offline execution.
- Maintain rootless security and compatibility with arbitrary UIDs.

## Decision Outcome
1. **Ruby Nexus Mirroring**:
   - Introduce `NEXUS_RUBY_URL` (with aliases `RUBYGEM_MIRROR_URL`, `RUBY_MIRROR_URL`).
   - `entrypoint.sh` automatically executes `bundle config set --global mirror.https://rubygems.org "${NEXUS_RUBY_URL}"` and updates `gem sources`.
   - If `NEXUS_USER` & `NEXUS_PASSWORD` are provided, Bundler authentication is automatically configured.
   - If no mirror variable is provided, standard public RubyGems is retained.
2. **Graceful Offline Fallback Engine**:
   - A single 2-second reachability probe evaluates target connectivity (Nexus or Google).
   - If the probe times out or fails (or if `OFFLINE_MODE=true` is set):
     - Skip all external downloads immediately (0ms blocking delay).
     - Dynamically generate `${GRADLE_USER_HOME}/init.d/fallback-offline.init.gradle` injecting `gradle.startParameter.offline = true`.
     - Set `BUNDLE_OFFLINE=true`.
     - Output an informative banner so pipelines succeed using cached dependencies instead of throwing `SocketTimeoutException`.
