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
| | `code_coverage` | Jacoco code coverage gate | `COVERAGE_THRESHOLD` (default: `80`) |
| | `security_scan` | Scan APK permissions & certificate expiry via apkanalyzer | *None required* |
| | `perf_baseline` | Jetpack Macrobenchmark metrics extracted to JSON | `BENCHMARK_MODULE`, `BENCHMARK_CLASS`, `BENCHMARK_OUTPUT` |
| **Packaging & Branding** | `build_debug` | Assemble Debug APK (`assembleDebug`) | *None required* |
| | `build_release` | Assemble Release APK (`assembleRelease`) | *None required* |
| | `bundle` | Assemble Release App Bundle (`bundleRelease`) | *None required* |
| | `badge` | Overlay visual ribbon badge on launcher icons | `BADGE_TEXT` (default: `BETA`), `BADGE_COLOR`, `BADGE_GRAVITY` (`bottom`/`top`) |
| | `apk_size_audit` | Warn on artifact size regressions vs baseline | `APK_SIZE_BASELINE_MB`, `APK_SIZE_WARN_THRESHOLD_PCT` |
| **Signature & Security** | `sign` | Sign APKs or AAB with a Base64 Keystore | `KEYSTORE_BASE64` or `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` |
| **Distribution** | `distribute_firebase` | Deploy to Firebase App Distribution | `FIREBASE_APP_ID`, `FIREBASE_TOKEN`, `FIREBASE_GROUPS`, `FIREBASE_RELEASE_NOTES` |
| | `distribute_playstore` | Publish AAB to Google Play Console via Supply | `GOOGLE_PLAY_KEY_BASE64` or `SUPPLY_JSON_KEY`, `PLAY_TRACK`, `PLAY_ROLLOUT_PERCENTAGE` |
| | `deploy_alpha` | Google Play internal track shortcut | `GOOGLE_PLAY_KEY_BASE64` or `SUPPLY_JSON_KEY` |
| | `deploy_production` | Google Play production shortcut with rollout | `GOOGLE_PLAY_KEY_BASE64`, `PLAY_ROLLOUT_PERCENTAGE` (default: 10%) |
| | `distribute_github` | Upload release artifacts to GitHub Release | `GITHUB_REF_NAME` or `CI_COMMIT_TAG` |
| | `app_center` | Distribute to Microsoft App Center | `APPCENTER_API_TOKEN`, `APPCENTER_OWNER_NAME`, `APPCENTER_APP_NAME` |
| | `deploy_huawei` | Publish to Huawei AppGallery Connect | `HUAWEI_CLIENT_ID`, `HUAWEI_CLIENT_SECRET`, `HUAWEI_APP_ID` |
| | `deploy_samsung` | Publish to Samsung Galaxy Store | `SAMSUNG_SERVICE_ACCOUNT`, `SAMSUNG_ACCESS_KEY`, `SAMSUNG_CONTENT_ID` |
| **Version Control** | `changelog` | Generate CHANGELOG.md from Conventional Commits | `CHANGELOG_FILE` (default: `CHANGELOG.md`) |
| | `git_tag` | Create and push Git tag from app versionName | `GIT_TAG_NAME` (optional override) |
| **ChatOps & Alerting** | `notify_slack` | Send build status card to Slack | `SLACK_WEBHOOK_URL`, `SLACK_CHANNEL`, `CI_BUILD_STATUS` |
| | `notify_teams` | Send build status card to Microsoft Teams | `TEAMS_WEBHOOK_URL`, `CI_BUILD_STATUS` |
| | `notify` | Smart multi-channel auto-dispatch | `SLACK_WEBHOOK_URL`, `TEAMS_WEBHOOK_URL`, `DISCORD_WEBHOOK_URL`, `TELEGRAM_BOT_TOKEN` |
| **Composite Pipeline** | `all` | Full CI chain (`lint` ➔ `detekt` ➔ `test` ➔ `build_release` ➔ `bundle`) | *None required* |
| | `release` | Complete release (`sign` ➔ `bundle` ➔ `stores` ➔ `git_tag` ➔ `changelog` ➔ `notify`) | Keystore & store credentials |
| | `clean` | Clean Gradle cache and terminate daemons | *None required* |

---

## 📊 Universal CI Summary & Sticky PR/MR Reporting

Starting with **v1.7.2**, `ci-lane` automatically captures domain metrics after every lane execution and publishes an executive Markdown report across your CI platform:

### 1. Platform Integrations
- **GitHub Actions**: Automatically appends to `$GITHUB_STEP_SUMMARY`. Also updates a sticky PR comment (`<!-- ci-lane-summary -->`) without spamming notifications.
- **GitLab CI**: Saves cumulative report to `build/reports/ci-lane-summary.md` and root `ci-lane-summary.md` (exportable via `artifacts: paths`). Updates Merge Request note if `GITLAB_TOKEN` or `CI_JOB_TOKEN` is available.
- **Bitrise**: Injects into step summary and artifacts directory.
- **Terminal Console**: Renders a high-visibility ANSI colored diagnostic card directly in the runner log.

### 2. Diagnostic 360° Metrics
- **Unit Tests**: Parsed from JUnit XML (`passed / total`, names of failing test methods).
- **Android Lint**: Total errors and warnings count.
- **Code Coverage**: Jacoco line coverage percentage.
- **Artifacts**: Discovered APK/AAB outputs with exact file sizes in MB.
- **Failure Diagnostics**: In case of failure, automatically isolates the failing Gradle task and the relevant error stacktrace inside a collapsible section.

### 3. Configuration Variables
| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `CI_LANE_SUMMARY` | `true` | Enables/disables automatic summary generation. |
| `CI_LANE_COMMENT_PR` | `true` | Enables/disables sticky comment updates on GitHub PRs and GitLab MRs. |
| `CI_LANE_FAIL_SILENT` | `false` | When `true`, suppresses non-zero exit codes on lane failures. |
