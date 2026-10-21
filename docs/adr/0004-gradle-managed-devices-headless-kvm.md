# ADR 0004: Native Gradle Managed Devices (GMD) and Headless KVM Virtualization

- **Status**: Accepted
- **Date**: 2026-10-21
- **Deciders**: Hatem Noureddine, AI Pair Programming Agent

## Context and Problem Statement
Running Android instrumented tests in CI has historically required brittle custom scripts (spawning emulator processes in the background, polling ADB `getprop sys.boot_completed`, handling display rendering crashes, and killing processes). Android Gradle Plugin introduced **Gradle Managed Devices (GMD)** to manage emulator lifecycle directly from `build.gradle`.

## Decision Drivers
- Zero custom orchestration scripts required by developer teams.
- Seamless execution of `./gradlew <device>DebugAndroidTest`.
- High-performance headless execution without X11 or physical GPUs.
- Support for modern form factors (Pixel phones, 7.6in Foldable devices).

## Decision Outcome
Chosen option: **Native Pre-Configured GMD Platform Support**.
1. Pre-install the Android SDK `emulator` package into the image on `amd64`.
2. Install headless graphics and rendering dependencies (`libpng16`, `libgl1`, `libegl1`, `libvulkan1`, `libpulse0`, `libnss3`).
3. Auto-inject headless GMD properties into `gradle.properties`:
   - `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect`
   - `android.testoptions.manageddevices.emulator.showKernelLogging=true`
   - `android.experimental.testoptions.manageddevices.maxconcurrentdevices=1`
4. Set universal read/write permissions (`777`) on `ANDROID_AVD_HOME` (`/home/runner/.android/avd`).
5. Ensure `/dev/kvm` accessibility when mounted.

## Multi-Architecture Note
Google publishes the Linux Android SDK Emulator package exclusively for `x86_64`. On ARM64 Linux hosts, compilation, linting, and unit tests run at native speed, but GMD emulator execution requires `x86_64` runners.
