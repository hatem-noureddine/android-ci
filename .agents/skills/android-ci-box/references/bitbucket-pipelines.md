# Bitbucket Pipelines Integration Guide (`hateum/android-ci-box`)

This guide explains how to execute Android CI/CD pipelines in Atlassian Bitbucket Pipelines using `hateum/android-ci-box`.

---

## 1. Pipeline Overview

Bitbucket Pipelines runs steps directly inside Docker containers. Because Android compilation and AGP need ample RAM, use `size: 2x` (8GB RAM) for Android steps.

```yaml
image: hateum/android-ci-box:latest

definitions:
  caches:
    gradlewrapper: ~/.gradle/wrapper
    gradlecaches: ~/.gradle/caches

pipelines:
  default:
    - step:
        name: Build and Test
        caches:
          - gradlewrapper
          - gradlecaches
        size: 2x
        script:
          - ci-doctor --summary
          - ./gradlew lintRelease testReleaseUnitTest assembleRelease --no-daemon
        artifacts:
          - app/build/outputs/apk/release/*.apk
          - app/build/outputs/bundle/release/*.aab
```

---

## 2. Ready-to-Use Template

A complete template is available at [`examples/ci/bitbucket-pipelines.yml`](../../../examples/ci/bitbucket-pipelines.yml).
