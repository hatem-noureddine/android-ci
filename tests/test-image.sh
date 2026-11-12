#!/bin/bash
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "\n${BOLD}${CYAN}================================================================${RESET}"
echo -e "${BOLD}${CYAN}          Android CI Box - Comprehensive Test Suite             ${RESET}"
echo -e "${BOLD}${CYAN}================================================================${RESET}\n"

# ------------------------------------------------------------------------------
# Test 1: Run CI Doctor (Interactive & JSON Summary Modes)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 1/7] Running ci-doctor verification (Interactive & JSON modes)...${RESET}"
ci-doctor
echo -e "Testing ci-doctor --json output validation..."
DOCTOR_JSON=$(ci-doctor --json)
echo "$DOCTOR_JSON" | python3 -m json.tool >/dev/null
DOCTOR_STATUS=$(echo "$DOCTOR_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status'))")
if [ "$DOCTOR_STATUS" != "healthy" ]; then
    echo -e "${RED}✘ Expected status 'healthy' but got '${DOCTOR_STATUS}'!${RESET}"
    exit 1
fi
echo -e "${GREEN}✔ ci-doctor passed successfully (Interactive & JSON modes)!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 2: Dual JDK Switching (Direct execution & Sourcing)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 2/7] Testing JDK switching (17 vs 21, binary execution & sourcing)...${RESET}"
switch-jdk 17
JAVA_17_VER=$(java -version 2>&1 | head -n 1)
echo "Active Java (Binary switch 17): $JAVA_17_VER"
if [[ "$JAVA_17_VER" != *"17."* ]]; then
    echo -e "${RED}✘ Failed to switch to JDK 17!${RESET}"
    exit 1
fi

# Test sourcing to export JAVA_HOME directly to shell environment
# shellcheck source=/dev/null
source switch-jdk 21
echo "Active JAVA_HOME (Sourced switch 21): $JAVA_HOME"
JAVA_21_VER=$(java -version 2>&1 | head -n 1)
echo "Active Java (Sourced switch 21): $JAVA_21_VER"
if [[ "$JAVA_21_VER" != *"21."* ]] || [ "$JAVA_HOME" != "/opt/jdk-21" ]; then
    echo -e "${RED}✘ Failed to switch to JDK 21 via sourcing!${RESET}"
    exit 1
fi
echo -e "${GREEN}✔ JDK switching passed (Binary & Sourcing)!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 3: Android SDK Components Verification
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 3/7] Verifying Android SDK platforms & build-tools...${RESET}"
for api in 35 36 37; do
    if [ -d "$ANDROID_HOME/platforms/android-$api" ]; then
        echo -e "  Found platform: ${GREEN}android-$api${RESET}"
    else
        echo -e "${RED}✘ Missing platform android-$api!${RESET}"
        exit 1
    fi
done

for bt in "35.0.0" "36.0.0" "37.0.0"; do
    if [ -d "$ANDROID_HOME/build-tools/$bt" ]; then
        echo -e "  Found build-tools: ${GREEN}$bt${RESET}"
    else
        echo -e "${RED}✘ Missing build-tools $bt!${RESET}"
        exit 1
    fi
done
echo -e "${GREEN}✔ Android SDK components verified!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 4: Tooling Executables Verification (CLI, PEP 668, SDK installer)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 4/7] Verifying CLI tools (gradle, android, emulator, bundletool, fastlane, python, gh)...${RESET}"
gradle --version
android --version
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    (emulator -version 2>&1 || true) | head -n 2
fi
bundletool version
fastlane --version
RUBY_VER=$(ruby -v 2>&1 | awk '{print $2}')
echo "Ruby active: $RUBY_VER"
if [[ "$RUBY_VER" != 4.0* ]]; then
    echo -e "${RED}✘ Expected Ruby 4.0.x but got ${RUBY_VER}!${RESET}"
    exit 1
fi
python3 --version
pip --version

# Verify Python PEP 668 bypass configuration
echo "Verifying Python pip PEP 668 bypass..."
if [ -f /etc/pip.conf ] && grep -q "break-system-packages = true" /etc/pip.conf; then
    python3 -m pip install --dry-run --no-deps setuptools >/dev/null 2>&1 || true
    echo -e "${GREEN}✔ Pip PEP 668 bypass active (/etc/pip.conf)!${RESET}"
else
    echo -e "${RED}✘ /etc/pip.conf missing break-system-packages = true!${RESET}"
    exit 1
fi

# Verify install-sdk-version CLI usage
echo "Verifying install-sdk-version CLI interface..."
SDK_USAGE=$(install-sdk-version --help 2>&1 || true)
if echo "$SDK_USAGE" | grep -q "Usage: install-sdk-version"; then
    echo -e "${GREEN}✔ install-sdk-version CLI interface verified!${RESET}"
else
    echo -e "${RED}✘ install-sdk-version CLI failed argument check!${RESET}"
    exit 1
fi

# Verify detect-android-project CLI usage
echo "Verifying detect-android-project CLI interface & detection..."
DETECT_OUT=$(detect-android-project /project/test_projects/SampleProject)
echo "$DETECT_OUT"
if echo "$DETECT_OUT" | grep -q "Android Project       : Yes" && \
   echo "$DETECT_OUT" | grep -q "Target compileSdk     : 37" && \
   echo "$DETECT_OUT" | grep -q "Target Java Version   : 17"; then
    echo -e "${GREEN}✔ detect-android-project correctly detected SampleProject requirements!${RESET}"
else
    echo -e "${RED}✘ detect-android-project failed detection check!${RESET}"
    exit 1
fi

DETECT_JSON=$(detect-android-project /project/test_projects/SampleProject --json)
echo "$DETECT_JSON" | python3 -m json.tool >/dev/null
DETECTED_SDK_JSON=$(echo "$DETECT_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('compile_sdk'))")
if [ "$DETECTED_SDK_JSON" = "37" ]; then
    echo -e "${GREEN}✔ detect-android-project --json output is valid!${RESET}"
else
    echo -e "${RED}✘ detect-android-project --json unexpected compile_sdk: $DETECTED_SDK_JSON!${RESET}"
    exit 1
fi

gh --version
echo -e "${GREEN}✔ All CLI tools verified!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 5: Enterprise Network & Entrypoint Simulation
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 5/7] Testing enterprise auto-detection (Proxy, CA & Nexus)...${RESET}"
TEST_GRADLE_DIR="/tmp/test_gradle_home"
mkdir -p "$TEST_GRADLE_DIR"
GRADLE_USER_HOME="$TEST_GRADLE_DIR" \
HTTP_PROXY="http://proxy.test.internal:8080" \
NO_PROXY="localhost,127.0.0.1,test.internal" \
NEXUS_BASE_URL="https://nexus.test.internal/repository" \
GRADLE_BUILD_CACHE_URL="https://cache.test.internal/cache/" \
/entrypoint.sh echo "Entrypoint test executed successfully"

if grep -q "proxyHost=proxy.test.internal" "$TEST_GRADLE_DIR/gradle.properties" && \
   grep -q "proxyPort=8080" "$TEST_GRADLE_DIR/gradle.properties" && \
   grep -q "nonProxyHosts=localhost|127.0.0.1|test.internal" "$TEST_GRADLE_DIR/gradle.properties"; then
    echo -e "${GREEN}✔ Corporate proxy settings injected into gradle.properties successfully!${RESET}"
else
    echo -e "${RED}✘ Proxy settings missing or malformed in gradle.properties!${RESET}"
    cat "$TEST_GRADLE_DIR/gradle.properties"
    exit 1
fi

if [ -f "$TEST_GRADLE_DIR/init.d/nexus-mirror.init.gradle" ]; then
    echo -e "${GREEN}✔ Nexus auto-derivation generated init.d/nexus-mirror.init.gradle!${RESET}"
else
    echo -e "${RED}✘ Nexus mirror init script missing!${RESET}"
    ls -la "$TEST_GRADLE_DIR/init.d" || true
    exit 1
fi

if [ -f "$TEST_GRADLE_DIR/init.d/remote-build-cache.init.gradle" ]; then
    echo -e "${GREEN}✔ Remote build cache init script generated successfully!${RESET}"
else
    echo -e "${RED}✘ Remote build cache script missing!${RESET}"
    ls -la "$TEST_GRADLE_DIR/init.d" || true
    exit 1
fi

if grep -q "android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect" "$TEST_GRADLE_DIR/gradle.properties"; then
    echo -e "${GREEN}✔ Gradle Managed Devices (GMD) headless options injected successfully!${RESET}"
else
    echo -e "${RED}✘ GMD headless options missing in gradle.properties!${RESET}"
    exit 1
fi

rm -rf "$TEST_GRADLE_DIR"

echo "Testing entrypoint auto-switch via JAVA_VERSION=17..."
TEST_ENTRY_DIR="/tmp/test_entry_jdk"
mkdir -p "$TEST_ENTRY_DIR"
if GRADLE_USER_HOME="$TEST_ENTRY_DIR" JAVA_VERSION="17" /entrypoint.sh java -version 2>&1 | grep -q '17\.'; then
    echo -e "${GREEN}✔ entrypoint.sh auto-switched to JDK 17 via JAVA_VERSION=17!${RESET}"
else
    echo -e "${RED}✘ entrypoint.sh failed to switch JDK via JAVA_VERSION=17!${RESET}"
    exit 1
fi
rm -rf "$TEST_ENTRY_DIR"

echo "Testing entrypoint dynamic auto-detection from project files..."
TEST_ENTRY_AUTO="/tmp/test_entry_auto"
mkdir -p "$TEST_ENTRY_AUTO"
if (cd /project/test_projects/SampleProject && GRADLE_USER_HOME="$TEST_ENTRY_AUTO" /entrypoint.sh java -version 2>&1 | grep -q '17\.'); then
    echo -e "${GREEN}✔ entrypoint.sh dynamically detected and configured JDK 17 from SampleProject!${RESET}"
else
    echo -e "${RED}✘ entrypoint.sh failed project-based Java auto-switch!${RESET}"
    exit 1
fi
rm -rf "$TEST_ENTRY_AUTO"

echo -e "${GREEN}✔ Enterprise network integration & runtime customization verified!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 6: Real Android Compilation, AAB Build & Bundletool Extraction
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 6/7] Building and linting real Android project (SampleProject)...${RESET}"
cd /project/test_projects/SampleProject

chmod +x gradlew
echo "Running Gradle unit tests and Android Lint..."
./gradlew test lintRelease check --no-daemon

echo "Running Gradle assembleRelease..."
./gradlew assembleRelease --no-daemon

if [ -f "app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
    echo -e "${GREEN}✔ Release APK successfully generated:${RESET}"
    ls -lh app/build/outputs/apk/release/app-release-unsigned.apk
else
    echo -e "${RED}✘ Release APK not found!${RESET}"
    exit 1
fi

echo "Running Gradle bundleRelease (Android App Bundle AAB)..."
./gradlew bundleRelease --no-daemon

if [ -f "app/build/outputs/bundle/release/app-release.aab" ]; then
    echo -e "${GREEN}✔ Release AAB successfully generated:${RESET}"
    ls -lh app/build/outputs/bundle/release/app-release.aab
else
    echo -e "${RED}✘ Release AAB not found!${RESET}"
    exit 1
fi

echo "Verifying Bundletool universal APK generation from AAB..."
bundletool build-apks \
    --bundle="app/build/outputs/bundle/release/app-release.aab" \
    --output="/tmp/sample-app.apks" \
    --mode=universal
if [ -f "/tmp/sample-app.apks" ]; then
    echo -e "${GREEN}✔ Bundletool successfully generated .apks archive:${RESET}"
    ls -lh /tmp/sample-app.apks
    unzip -l /tmp/sample-app.apks | grep -E "universal.apk|toc.pb"
    rm -f /tmp/sample-app.apks
else
    echo -e "${RED}✘ Bundletool failed to build .apks!${RESET}"
    exit 1
fi

echo "Running Gradle assembleDebugAndroidTest (Instrumentation test APK with GMD support)..."
./gradlew assembleDebugAndroidTest --no-daemon

if [ -f "app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk" ]; then
    echo -e "${GREEN}✔ Instrumentation test APK successfully generated:${RESET}"
    ls -lh app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
else
    echo -e "${RED}✘ Instrumentation test APK not found!${RESET}"
    exit 1
fi
echo -e "${GREEN}✔ Android compilation, AAB, bundletool & instrumentation build test passed!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 7: Fastlane Test Lane Execution
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 7/7] Executing Fastlane test lanes...${RESET}"
bundle exec fastlane android test_ci
bundle exec fastlane test
echo -e "${GREEN}✔ Fastlane test lanes executed successfully!${RESET}\n"

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   ✔ ALL 7 TESTS PASSED SUCCESSFULLY! THE IMAGE IS CERTIFIED.   ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}\n"
