# Gradle Managed Devices (GMD) & Headless Emulators Reference

This guide details best practices, DSL patterns, and troubleshooting steps for running instrumented tests inside `hateum/android-ci-box` using Gradle Managed Devices (GMD) and headless Android SDK emulators.

---

## 1. Why GMD in CI/CD?

Legacy CI Android testing required brittle bash scripts to boot AVDs in the background, poll `adb shell getprop sys.boot_completed`, and manage locks.
With **Gradle Managed Devices (GMD)**:
- AGP handles downloading the required system image, generating the AVD, launching it headlessly, executing the tests, collecting recordings/screenshots, and terminating the emulator cleanly.
- Tests can run on **Automated Test Device (ATD)** images, which are stripped of background services and Google apps for 4x faster test execution and reduced RAM usage.

---

## 2. Configuration Patterns (`build.gradle` / `build.gradle.kts`)

### Groovy DSL (`app/build.gradle`)

```groovy
android {
    testOptions {
        animationsDisabled = true
        managedDevices {
            allDevices {
                // Standard ATD device (fastest, lightweight)
                pixel8api35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Pixel 8"
                    apiLevel = 35
                    systemImageSource = "google-atd" // Options: "google-atd", "aosp-atd", "google", "aosp"
                }

                // Modern Android 16 / API 36 test target
                pixel9api36(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Pixel 9"
                    apiLevel = 36
                    systemImageSource = "google-atd"
                }

                // Foldable screen form factor
                foldableApi35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "7.6in Foldable"
                    apiLevel = 35
                    systemImageSource = "google"
                }

                // Tablet screen form factor
                tabletApi35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Nexus 10"
                    apiLevel = 35
                    systemImageSource = "google"
                }
            }

            // Grouping devices for aggregate test execution
            deviceGroups {
                phoneAndTablet {
                    targetDevices.add(devices.pixel8api35)
                    targetDevices.add(devices.tabletApi35)
                }
            }
        }
    }
}
```

### Kotlin DSL (`app/build.gradle.kts`)

```kotlin
android {
    testOptions {
        animationsDisabled = true
        managedDevices {
            devices {
                maybeCreate<com.android.build.api.dsl.ManagedVirtualDevice>("pixel8api35").apply {
                    device = "Pixel 8"
                    apiLevel = 35
                    systemImageSource = "google-atd"
                }
                maybeCreate<com.android.build.api.dsl.ManagedVirtualDevice>("foldableApi35").apply {
                    device = "7.6in Foldable"
                    apiLevel = 35
                    systemImageSource = "google"
                }
            }
        }
    }
}
```

---

## 3. Running GMD Tests

```bash
# Run tests on a single managed device
./gradlew pixel8api35DebugAndroidTest --no-daemon

# Run tests on a device group
./gradlew phoneAndTabletGroupDebugAndroidTest --no-daemon

# Run all configured managed device tests
./gradlew allDevicesDebugAndroidTest --no-daemon
```

---

## 4. Architecture Nuances (`amd64` vs `arm64`)

> [!WARNING]
> **Google SDK Emulator Limitation**:
> Google only provides the Linux Android SDK emulator package (`emulator`) for `x86_64` (`amd64`). There is **no native Linux arm64 emulator package** published by Google.
> 
> - On **`amd64` runners**: Full native KVM acceleration is supported. GMD downloads `x86_64` ATD system images and runs at near-native speeds.
> - On **`arm64` runners**: Core compilation (`assembleRelease`), linting (`lintRelease`), and unit tests (`testReleaseUnitTest`) run at maximum native speed. However, GMD instrumented tests requiring the Linux emulator should be tagged or routed to `amd64` runners with `/dev/kvm`.

---

## 5. Troubleshooting Headless Emulators in CI

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| `Cannot open /dev/kvm: No such file or directory` | Runner host lacks hardware virtualization or nested virtualization | Enable nested virtualization on VM host, or map `--device /dev/kvm` in Docker / GitLab Runner. |
| `Cannot open /dev/kvm: Permission denied` | Host permissions restrict `/dev/kvm` to root | Run `sudo chmod 666 /dev/kvm` on the host, or add runner user to `kvm` group. |
| Emulator exits with code `137` | CI Runner Out Of Memory (OOMKilled) | Limit concurrency: `android.experimental.testoptions.manageddevices.maxconcurrentdevices=1`, and assign >= 8GB RAM to container. |
| Crash with `libGL error: unable to load driver: swrast_dri.so` | Headless rendering attempting to use hardware GPU without X11/Wayland | Inject `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` (handled automatically by container entrypoint). |
