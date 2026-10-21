# GitHub Actions Integration Guide (`hateum/android-ci-box`)

This guide explains how to run Android compilation, linting, unit testing, and Gradle Managed Devices (GMD) emulators on GitHub Actions using `hateum/android-ci-box`.

---

## 1. Execution Modes

### Mode A: Container Job (`runs-on: ubuntu-latest`)
GitHub Actions allows running the entire job inside a Docker container:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: hateum/android-ci-box:latest
      options: --user 1000:0
    steps:
      - uses: actions/checkout@v4
      - run: ./gradlew assembleRelease --no-daemon
```
*Note*: GitHub-hosted `ubuntu-latest` runners typically do not expose nested virtualization `/dev/kvm`. Mode A is ideal for linting, compilation, and unit tests.

### Mode B: Self-Hosted Runner or KVM-Enabled Virtualization for GMD
For instrumented tests requiring `/dev/kvm`, run `docker run` directly on an instance with hardware acceleration (e.g., AWS `.metal`, GCP with nested virtualization, or self-hosted bare metal):
```yaml
jobs:
  instrumented-tests:
    runs-on: [self-hosted, linux, kvm]
    steps:
      - uses: actions/checkout@v4
      - name: Run GMD Tests
        run: |
          docker run --rm \
            --device /dev/kvm \
            -v "${{ github.workspace }}":/project \
            -w /project \
            hateum/android-ci-box:latest \
            ./gradlew pixel8api35DebugAndroidTest --no-daemon
```

---

## 2. Gradle Caching on GitHub Actions

Use `actions/cache@v4` targeting `~/.gradle/caches` and `~/.gradle/wrapper`:
```yaml
- name: Cache Gradle Packages
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    restore-keys: |
      ${{ runner.os }}-gradle-
```

---

## 3. Ready-to-Use Template

A complete production workflow is available at [`examples/ci/github-actions.yml`](../../../examples/ci/github-actions.yml).
