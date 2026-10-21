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
# Test 1: Run CI Doctor
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 1/7] Running ci-doctor verification...${RESET}"
ci-doctor
echo -e "${GREEN}✔ ci-doctor passed successfully!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 2: Dual JDK Switching
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 2/7] Testing JDK switching (17 vs 21)...${RESET}"
switch-jdk 17
JAVA_17_VER=$(java -version 2>&1 | head -n 1)
echo "Active Java: $JAVA_17_VER"
if [[ "$JAVA_17_VER" != *"17."* ]]; then
    echo -e "${RED}✘ Failed to switch to JDK 17!${RESET}"
    exit 1
fi

switch-jdk 21
JAVA_21_VER=$(java -version 2>&1 | head -n 1)
echo "Active Java: $JAVA_21_VER"
if [[ "$JAVA_21_VER" != *"21."* ]]; then
    echo -e "${RED}✘ Failed to switch to JDK 21!${RESET}"
    exit 1
fi
echo -e "${GREEN}✔ JDK switching passed!${RESET}\n"

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
# Test 4: Tooling Executables Verification
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 4/7] Verifying CLI tools (gradle, bundletool, fastlane, python, gh)...${RESET}"
gradle --version
bundletool version
fastlane --version
python3 --version
pip --version
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

if [ -f "$TEST_GRADLE_DIR/init.d/nexus-mirror.gradle" ]; then
    echo -e "${GREEN}✔ Nexus auto-derivation generated init.d/nexus-mirror.gradle!${RESET}"
else
    echo -e "${RED}✘ Nexus mirror init script missing!${RESET}"
    exit 1
fi

if [ -f "$TEST_GRADLE_DIR/init.d/remote-cache.gradle" ]; then
    echo -e "${GREEN}✔ Remote build cache init script generated successfully!${RESET}"
else
    echo -e "${RED}✘ Remote build cache script missing!${RESET}"
    exit 1
fi
rm -rf "$TEST_GRADLE_DIR"
echo -e "${GREEN}✔ Enterprise network integration verified!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 6: Real Android Compilation & Linters (SampleProject)
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
echo -e "${GREEN}✔ Android compilation & lint test passed!${RESET}\n"

# ------------------------------------------------------------------------------
# Test 7: Fastlane Test Lane Execution
# ------------------------------------------------------------------------------
echo -e "${BOLD}[Test 7/7] Executing Fastlane test lane...${RESET}"
bundle exec fastlane test
echo -e "${GREEN}✔ Fastlane test lane executed successfully!${RESET}\n"

echo -e "\n${BOLD}${GREEN}================================================================${RESET}"
echo -e "${BOLD}${GREEN}   ✔ ALL 7 TESTS PASSED SUCCESSFULLY! THE IMAGE IS CERTIFIED.   ${RESET}"
echo -e "${BOLD}${GREEN}================================================================${RESET}\n"
