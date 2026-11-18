# Turnkey Android CI/CD Lanes (`ci-lane`)

`ci-lane` is an autonomous, turnkey Fastlane runner embedded directly inside `hateum/android-ci-box`.

It allows mobile development teams to execute complete build, test, lint, badge, signature, and store distribution workflows **in a single line of CI configuration**, with **zero Fastfile or Ruby setup required** in their Android repository.

---

## ⚡ Key Highlights

- **Zero Project Setup**: No `Gemfile`, no `fastlane/Fastfile`, no bundler commands needed in the Android project.
- **Smart Dual-Routing**:
  - If your project contains its own `fastlane/Fastfile`, `ci-lane` executes your custom lanes seamlessly.
  - If your project does **not** have a Fastfile, `ci-lane` automatically executes the **universal built-in Fastfile** (`/opt/fastlane/Fastfile`).
- **Complete Lifecycle Coverage**: Unit tests, Android Lint, Detekt, SonarQube, Icon Badging, APK/AAB builds, Keystore signing, Firebase & Google Play distribution, and multi-channel ChatOps (Slack, Teams, Discord, Telegram).

---

## 🚀 1-Line CI/CD Integration Examples

### 1. GitLab CI (`.gitlab-ci.yml`)

```yaml
stages:
  - test
  - deploy

unit_and_lint:
  stage: test
  image: hateum/android-ci-box:slim
  script:
    - ci-lane lint
    - ci-lane test

deploy_firebase:
  stage: deploy
  image: hateum/android-ci-box:slim
  only: [develop]
  script:
    - ci-lane badge
    - ci-lane build_debug
    - ci-lane distribute_firebase
  variables:
    BADGE_TEXT: "QA"
    FIREBASE_APP_ID: "1:123456789:android:abcdef"
    FIREBASE_TOKEN: "$FIREBASE_CI_TOKEN"

deploy_playstore:
  stage: deploy
  image: hateum/android-ci-box:slim
  only: [tags]
  script:
    - ci-lane bundle
    - ci-lane sign
    - ci-lane distribute_playstore
    - ci-lane notify_slack
  variables:
    PLAY_TRACK: "internal"
    KEYSTORE_BASE64: "$PROD_KEYSTORE_B64"
    KEYSTORE_PASSWORD: "$KEYSTORE_PASSWORD"
    KEY_ALIAS: "$KEY_ALIAS"
    GOOGLE_PLAY_KEY_BASE64: "$GOOGLE_PLAY_JSON_B64"
    SLACK_WEBHOOK_URL: "$SLACK_WEBHOOK_URL"
```

---

### 2. GitHub Actions (`.github/workflows/android.yml`)

```yaml
name: Android Turnkey CI

on:
  push:
    branches: [ main, develop ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-24.04
    container:
      image: hateum/android-ci-box:slim
    steps:
      - uses: actions/checkout@v5

      # Run complete turnkey pipeline in one command
      - name: Run Full Quality & Release Pipeline
        run: ci-lane all

      - name: Deploy to Firebase App Distribution
        if: github.ref == 'refs/heads/develop'
        env:
          FIREBASE_APP_ID: ${{ secrets.FIREBASE_APP_ID }}
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: ci-lane distribute_firebase
```

---

### 3. Bitrise (`bitrise.yml`)

Add a standard **Script Step** pointing to the container:

```bash
#!/bin/bash
ci-lane all
ci-lane distribute_firebase
```

---

## 📖 Complete Built-in Lanes Catalog

Run `ci-lane list` inside any container to display the live catalog:

| Category | Lane Name | Purpose | Config Environment Variables |
| :--- | :--- | :--- | :--- |
| **Quality & Tests** | `test` | Run JUnit unit tests across all modules | *None required* |
| | `lint` | Run Android Lint static analysis | *None required* |
| | `detekt` | Run Detekt Kotlin static analysis | *None required* |
| | `sonar` | Run SonarQube / SonarCloud scanner | `SONAR_TOKEN`, `SONAR_HOST_URL` |
| | `screenshot_tests` | Run Roborazzi or Paparazzi verification tasks | *None required* |
| **Packaging & Branding** | `build_debug` | Assemble Debug APK (`assembleDebug`) | *None required* |
| | `build_release` | Assemble Release APK (`assembleRelease`) | *None required* |
| | `bundle` | Assemble Release App Bundle (`bundleRelease`) | *None required* |
| | `badge` | Overlay visual ribbon badge on launcher icons | `BADGE_TEXT` (default: `BETA`), `BADGE_COLOR`, `BADGE_GRAVITY` (`bottom`/`top`) |
| **Signature & Security** | `sign` | Sign APKs or AAB with a Base64 Keystore | `KEYSTORE_BASE64` or `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` |
| **Distribution** | `distribute_firebase` | Deploy to Firebase App Distribution | `FIREBASE_APP_ID`, `FIREBASE_TOKEN`, `FIREBASE_GROUPS`, `FIREBASE_RELEASE_NOTES` |
| | `distribute_playstore` | Publish AAB to Google Play Console via Supply | `GOOGLE_PLAY_KEY_BASE64` or `SUPPLY_JSON_KEY`, `PLAY_TRACK` (`internal`, `alpha`, `beta`, `production`), `PLAY_ROLLOUT_PERCENTAGE` |
| | `distribute_github` | Upload release artifacts to GitHub Release | `GITHUB_REF_NAME` or `CI_COMMIT_TAG` |
| **ChatOps & Alerting** | `notify_slack` | Send build status card to Slack | `SLACK_WEBHOOK_URL`, `SLACK_CHANNEL`, `CI_BUILD_STATUS` |
| | `notify_teams` | Send build status card to Microsoft Teams | `TEAMS_WEBHOOK_URL`, `CI_BUILD_STATUS` |
| | `notify` | Smart multi-channel auto-dispatch | `SLACK_WEBHOOK_URL`, `TEAMS_WEBHOOK_URL`, `DISCORD_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN` |
| **Composite Pipeline** | `all` | Full chain (`lint` ➔ `detekt` ➔ `test` ➔ `build_release` ➔ `bundle`) | *None required* |
| | `clean` | Clean Gradle cache and terminate daemons | *None required* |
