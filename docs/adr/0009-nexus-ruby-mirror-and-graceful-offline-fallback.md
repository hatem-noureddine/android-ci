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
1. **Ruby Nexus Mirroring & Auto-Derivation**:
   - Introduce `NEXUS_RUBY_URL` (with aliases `RUBYGEM_MIRROR_URL`, `RUBY_MIRROR_URL`).
   - If `NEXUS_RUBY_URL` is omitted but `NEXUS_URL` is defined, auto-derive the Ruby mirror target path (e.g. `${NEXUS_BASE}/repository/rubygems-group/`).
   - Dual-injection: Sets both native Bundler environment variables (`BUNDLE_MIRROR__HTTPS://RUBYGEMS__ORG/`) and global configuration (`bundle config set --global`) with universal 777 permissions on `/home/runner/.bundle`.
   - If `NEXUS_USER` & `NEXUS_PASSWORD` are provided, Bundler authentication is automatically configured.
   - If no mirror variable is provided, standard public RubyGems is retained.
2. **Preserving 100% Normal Operation & Opt-In Offline Mode**:
   - By default, the container operates completely normally, with full network access for Gradle, Bundler, and SDK tooling.
   - The initial 2-second reachability probe ONLY gates container startup SDK/NDK auto-downloads to avoid stalling air-gapped CI; it NEVER forcibly locks Gradle into offline mode.
   - Strict offline build execution (`startParameter.offline = true` and `BUNDLE_OFFLINE=true`) is activated exclusively when `OFFLINE_MODE=true` is explicitly requested by the user.
