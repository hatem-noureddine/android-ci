# Complete CI/CD Integration Guides

This guide provides copy-pasteable, production-ready configurations for all major enterprise and open-source CI/CD engines using `hateum/android-ci-box`.

---

## 1. GitHub Actions

### Option A: Official Composite Action (Recommended)

The simplest and cleanest integration. Zero Docker daemon overhead on Ubuntu runners:

```yaml
# .github/workflows/android.yml
name: Android CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    name: Build & Test Android App
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Run Android CI Box Composite Action
        uses: hatem-noureddine/android-ci@v1
        with:
          version: 'latest' # or specific SemVer like '1.4.6'
          run: |
            ci-doctor
            ./gradlew test lintRelease assembleDebug --no-daemon
```

### Option B: Container Job Mode

Run the entire GitHub Actions job inside the container with volume and network sharing:

```yaml
# .github/workflows/android-container.yml
name: Android CI (Container Job)

on: [push, pull_request]

jobs:
  android-build:
    runs-on: ubuntu-latest
    container:
      image: hateum/android-ci-box:latest
      options: --user 1000:0

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Environment Diagnostics
        run: ci-doctor

      - name: Run Unit Tests & Build APK
        run: |
          ./gradlew test lintRelease assembleRelease --no-daemon

      - name: Deploy via Fastlane
        if: github.ref == 'refs/heads/main'
        env:
          GOOGLE_PLAY_KEY: ${{ secrets.GOOGLE_PLAY_KEY }}
        run: |
          bundle exec fastlane deploy_internal
```

---

## 2. GitLab CI/CD

Optimized for shared GitLab Runners, Kubernetes executors, and rootless environments with aggressive caching:

```yaml
# .gitlab-ci.yml
image: hateum/android-ci-box:latest

variables:
  GRADLE_OPTS: "-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true -Dorg.gradle.caching=true"
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"

cache:
  key: "${CI_COMMIT_REF_SLUG}-android"
  paths:
    - .gradle/wrapper/
    - .gradle/caches/

stages:
  - test
  - build
  - deploy

before_script:
  - ci-doctor --json > ci-env.json

unit_tests:
  stage: test
  script:
    - ./gradlew test lintRelease --stacktrace
  artifacts:
    when: always
    reports:
      junit: app/build/test-results/testDebugUnitTest/TEST-*.xml
    paths:
      - app/build/reports/lint-results-release.html

assemble_release:
  stage: build
  script:
    - ./gradlew assembleRelease
  artifacts:
    expire_in: 7 days
    paths:
      - app/build/outputs/apk/release/*.apk
      - app/build/outputs/bundle/release/*.aab

fastlane_deploy:
  stage: deploy
  only:
    - tags
  script:
    - bundle exec fastlane release
```

---

## 3. Jenkins (Declarative Pipeline)

Supports Jenkins agents running Docker with automatic workspace mount and user mapping:

```groovy
// Jenkinsfile
pipeline {
    agent {
        docker {
            image 'hateum/android-ci-box:latest'
            args  '--user 1000:0 -v /var/cache/gradle:/home/runner/.gradle'
        }
    }

    environment {
        ANDROID_HOME = '/opt/android-sdk'
        GRADLE_USER_HOME = '/home/runner/.gradle'
    }

    stages {
        stage('Diagnostics') {
            steps {
                sh 'ci-doctor'
                sh 'detect-android-project /project'
            }
        }

        stage('Lint & Unit Tests') {
            steps {
                sh './gradlew test lintRelease --no-daemon'
            }
            post {
                always {
                    junit '**/build/test-results/**/*.xml'
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/build/reports',
                        reportFiles: 'lint-results-release.html',
                        reportName: 'Android Lint Report'
                    ])
                }
            }
        }

        stage('Assemble Release') {
            steps {
                sh './gradlew assembleRelease --no-daemon'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'app/build/outputs/**/*.apk, app/build/outputs/**/*.aab', fingerprint: true
                }
            }
        }
    }
}
```

---

## 4. Bitbucket Pipelines

Ideal for Atlassian cloud or self-hosted runners:

```yaml
# bitbucket-pipelines.yml
image: hateum/android-ci-box:latest

definitions:
  caches:
    gradle: ~/.gradle/caches
    gradle-wrapper: ~/.gradle/wrapper

pipelines:
  default:
    - step:
        name: Build & Test
        caches:
          - gradle
          - gradle-wrapper
        script:
          - ci-doctor
          - ./gradlew test lint assembleDebug --no-daemon
        artifacts:
          - app/build/outputs/apk/debug/*.apk

  branches:
    main:
      - step:
          name: Production Release & Fastlane
          caches:
            - gradle
            - gradle-wrapper
          script:
            - ./gradlew assembleRelease bundleRelease --no-daemon
            - bundle exec fastlane deploy_google_play
          artifacts:
            - app/build/outputs/bundle/release/*.aab
```

---

## 5. CircleCI

High-speed container execution using CircleCI Docker executor:

```yaml
# .circleci/config.yml
version: 2.1

jobs:
  build-and-test:
    docker:
      - image: hateum/android-ci-box:latest
        user: runner
    working_directory: /project
    resource_class: large
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-gradle-wrapper-{{ checksum "gradle/wrapper/gradle-wrapper.properties" }}
            - v1-gradle-cache-{{ checksum "build.gradle" }}
      - run:
          name: Environment Healthcheck
          command: ci-doctor
      - run:
          name: Run Unit Tests & Lint
          command: ./gradlew test lintRelease --no-daemon
      - run:
          name: Build Release APK & Bundle
          command: ./gradlew assembleRelease bundleRelease --no-daemon
      - save_cache:
          paths:
            - ~/.gradle/caches
            - ~/.gradle/wrapper
          key: v1-gradle-cache-{{ checksum "build.gradle" }}
      - store_test_results:
          path: app/build/test-results
      - store_artifacts:
          path: app/build/outputs/bundle/release
          destination: bundles

workflows:
  build-workflow:
    jobs:
      - build-and-test
```

---

## 6. Azure DevOps Pipelines

Native integration with Azure Pipelines container jobs:

```yaml
# azure-pipelines.yml
trigger:
  - main
  - develop

pool:
  vmImage: 'ubuntu-latest'

container:
  image: hateum/android-ci-box:latest
  options: --user 1000:0

variables:
  GRADLE_USER_HOME: $(Pipeline.Workspace)/.gradle

steps:
  - script: ci-doctor
    displayName: 'Validate Android Environment'

  - script: ./gradlew test lintRelease --no-daemon
    displayName: 'Execute Unit Tests & Lint'

  - task: PublishTestResults@2
    condition: succeededOrFailed()
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: '**/build/test-results/**/*.xml'

  - script: ./gradlew assembleRelease bundleRelease --no-daemon
    displayName: 'Build Release APK and App Bundle'

  - task: PublishBuildArtifacts@1
    inputs:
      PathtoPublish: 'app/build/outputs'
      ArtifactName: 'android-build-artifacts'
```
