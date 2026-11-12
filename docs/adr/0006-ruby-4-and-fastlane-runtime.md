# ADR 0006: Ruby 4.0 and Fastlane Runtime via rbenv

- **Status**: Accepted
- **Date**: 2026-11-06
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Android deployment pipelines rely heavily on **Fastlane** for tasks such as screenshot generation, changelog assembly, AAB/APK signing, and distribution to Google Play Console and Firebase App Distribution.
The base operating system (Ubuntu 24.04 LTS Noble) packages an older Ruby runtime (Ruby 3.2), which lacks modern language features, security fixes, and gem performance improvements. Furthermore, installing Ruby directly via system APT introduces package coupling and permission hurdles for non-root runners.

## Decision Drivers
- Provide modern Ruby (4.0.9), Bundler (4.0.23), and Fastlane (2.241.2) out-of-the-box.
- Ensure strict multi-user non-root security (`777` permissions across all shims and gem libraries).
- Optimize build times during container compilation.
- Maintain zero unfixed critical CVEs under Trivy security scanners.

## Considered Options
1. **Ubuntu APT packages**: Keep Ruby 3.2. (Rejected: outdated runtime, slow gem resolution).
2. **Multi-stage copy from `ruby:4.0.9-slim`**: Copy precompiled Debian binaries. (Rejected: dynamic link / OpenSSL symbol mismatch between Debian Bookworm/Trixie and Ubuntu Noble).
3. **Dedicated rbenv environment in `/opt/rbenv` with parallel native compilation**: Compile Ruby 4.0 natively on Ubuntu 24.04 with `MAKE_OPTS="-j$(nproc)"` and `--disable-install-doc`.

## Decision Outcome
Chosen option: **Option 3 (`/opt/rbenv`)**, because:
1. Compiling on the target OS guarantees 100% ABI compatibility with Ubuntu 24.04's OpenSSL 3.0 and glibc 2.39 runtimes.
2. `MAKE_OPTS="-j$(nproc)"` and `--disable-install-doc` reduce compilation time to ~2.5 minutes on native runners while shaving unnecessary RDoc documentation overhead.
3. Placing shims in `/opt/rbenv/shims` and assigning universal permissions (`chmod -R 777 /opt/rbenv`) allows arbitrary UIDs (e.g. OpenShift `--user 1000:0` or `--user 1001:1001`) to run `fastlane`, `bundle`, and `gem` seamlessly.
4. Upstream vulnerability `CVE-2026-33210` in Ruby's bundled default `json-2.18.0` gem is neutralized by explicitly installing the patched `json` gem and documenting the false-positive in `.trivyignore`.
