# ADR-0016: Multi-Stage Image Variants (Slim vs Full)

## Status
Accepted

## Context
As `hateum/android-ci-box` evolved to support comprehensive Android development, the container image grew to accommodate the complete official Android SDK tooling: 3 Android API platforms (35, 36, 37.0), build-tools, dual OpenJDK runtimes (17/21), precompiled Ruby 4.0.9 with Fastlane, and the full Google Android SDK Emulator with SwiftShader headless GPU acceleration.

While this "batteries-included" approach is ideal for end-to-end integration pipelines and Gradle Managed Devices (GMD) UI testing, many modern CI/CD jobs only perform:
- Static analysis & linting (`./gradlew lintRelease check`)
- Unit testing (`./gradlew testDebugUnitTest`)
- Release compilation (`./gradlew assembleRelease`)
- Store deployment via Fastlane (`bundle exec fastlane deploy`)

For these common workflows, downloading the emulator package (~500 MB compressed, ~1.5 GB uncompressed) introduces unnecessary network latency and runner disk pressure, especially on ephemeral cloud runners (GitHub Actions, GitLab SaaS, AWS CodeBuild).

Furthermore, Google does not provide an official Linux ARM64 emulator package, making the emulator present only on `amd64`.

## Decision
We introduce a **Multi-Stage Dockerfile architecture** producing two first-class multi-arch container variants:

1. **`slim` Variant (`hateum/android-ci-box:slim` and `:${VERSION}-slim`)**:
   - Built via the `AS slim` intermediate target in the multi-stage `Dockerfile`.
   - Contains the complete compilation and release toolchain: OpenJDK 17/21, Gradle 9.8.2, Android SDK APIs 35/36/37, build-tools, Bundletool, Ruby 4.0.9 + Fastlane, Python 3, GitHub CLI, and dual-mode enterprise networking.
   - **Excludes the Android SDK Emulator** package and SwiftShader dependencies.
   - Drastically reduces image download and unpack times (~35% smaller footprint).
   - Tagged as: `slim`, `${VERSION}-slim`, `${MAJOR}.${MINOR}-slim`, and `${MAJOR}-slim`.

2. **`full` Variant (`hateum/android-ci-box:latest` and `:${VERSION}`)**:
   - Inherits directly from `AS slim` (`FROM slim AS full`).
   - Appends the Android SDK Emulator on `linux/amd64` for Gradle Managed Devices (GMD) and headless UI testing.
   - Serves as the default target when running `docker build .` without `--target`, preserving 100% backward compatibility for existing pipelines.
   - Tagged as: `latest`, `${VERSION}`, `${MAJOR}.${MINOR}`, and `${MAJOR}`.

## Comparative Matrix

| Capability / Tool | `slim` Variant (`:slim`) | `full` Variant (`:latest`) |
| :--- | :--- | :--- |
| **Primary Use Cases** | Linting, Unit Tests, Assembly, Fastlane Deploy | End-to-End Instrumented Tests, GMD, Screenshot Tests |
| **Android SDK APIs (35, 36, 37.0)** | ✅ Yes | ✅ Yes |
| **Build Tools (35, 36, 37)** | ✅ Yes | ✅ Yes |
| **Dual OpenJDK (17 & 21)** | ✅ Yes (`switch-jdk`) | ✅ Yes (`switch-jdk`) |
| **Ruby 4.0.9 + Fastlane 2.241.2**| ✅ Yes | ✅ Yes |
| **Bundletool 1.18.3 & Android CLI**| ✅ Yes | ✅ Yes |
| **Dual-Mode Enterprise Network**| ✅ Yes (Auto-Proxy, CA Trust, Mirrors) | ✅ Yes (Auto-Proxy, CA Trust, Mirrors) |
| **Android SDK Emulator (GMD)** | ❌ No (Stripped) | ✅ Yes (Preinstalled on `amd64`) |
| **Image Size (Compressed)** | **~2.2 GB** | **~3.5 GB** |
| **Pull & Unpack Latency** | **Fastest (~35% faster download)** | Standard |

## Consequences
- **Positive**:
  - Developers can select `:slim` for standard CI pipelines to accelerate build execution and minimize cloud egress costs.
  - Teams running UI and instrumentation tests seamlessly select `:latest` / `:full`.
  - Zero duplication: `full` layers directly on top of `slim`, reusing 100% of cached base layers.
  - Full cryptographic signing (Cosign) and SBOM attestations (SPDX) are generated for both `slim` and `full` variants.
- **Negative**:
  - Increases matrix publishing complexity in `.github/workflows/docker-publish.yml` to publish both variant manifests.
