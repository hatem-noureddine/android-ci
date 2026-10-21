# CircleCI Integration Guide (`hateum/android-ci-box`)

This guide explains how to configure CircleCI pipelines using `hateum/android-ci-box`.

---

## 1. Executor Setup

Define a Docker executor referencing `hateum/android-ci-box:latest`:

```yaml
version: 2.1

executors:
  android-container:
    docker:
      - image: hateum/android-ci-box:latest
        user: runner
    resource_class: xlarge # 16GB RAM / 8 vCPUs ensures fast builds without OOM
    working_directory: ~/project
```

---

## 2. Caching & Test Reporting

CircleCI natively supports JUnit test result collection via `store_test_results`:

```yaml
steps:
  - checkout
  - restore_cache:
      keys:
        - v1-gradle-{{ checksum "gradle/wrapper/gradle-wrapper.properties" }}-{{ checksum "app/build.gradle" }}
        - v1-gradle-
  - run:
      name: Lint & Unit Tests
      command: ./gradlew lintRelease testReleaseUnitTest check --no-daemon
  - store_test_results:
      path: app/build/test-results
  - store_artifacts:
      path: app/build/reports
      destination: reports
```

---

## 3. Ready-to-Use Template

A complete configuration template is available at [`examples/ci/circleci-config.yml`](../../../examples/ci/circleci-config.yml).
