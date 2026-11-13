#!/bin/bash
set -e

# ==============================================================================
# Universal Dual-Mode Network & CI Auto-Detection Engine
# Hardened for both Root and Non-Root (OpenShift / Kubernetes / GitLab Runner)
# ==============================================================================

# Determine active Gradle user home
GRADLE_DIR="${GRADLE_USER_HOME:-/home/runner/.gradle}"
mkdir -p "$GRADLE_DIR" "$GRADLE_DIR/init.d" 2>/dev/null || true

# ------------------------------------------------------------------------------
# 0. CI Environment Version Customization & Dynamic Project Auto-Detection
# ------------------------------------------------------------------------------
REQ_JAVA="${JAVA_VERSION:-${DEFAULT_JDK:-}}"
REQ_SDK="${INSTALL_SDK_VERSION:-${ANDROID_COMPILE_SDK:-}}"
REQ_BUILD_TOOLS="${INSTALL_BUILD_TOOLS:-${ANDROID_BUILD_TOOLS_VERSION:-}}"
REQ_NDK="${INSTALL_NDK_VERSION:-${ANDROID_NDK_VERSION:-}}"
REQ_CMAKE="${INSTALL_CMAKE_VERSION:-${CMAKE_VERSION:-}}"

# If any variable is missing and AUTO_DETECT_PROJECT != false, auto-detect from project
if [ "${AUTO_DETECT_PROJECT:-true}" != "false" ] && command -v detect-android-project >/dev/null 2>&1; then
    PROJ_DIR="${PROJECT_DIR:-$(pwd)}"
    if [ ! -f "$PROJ_DIR/build.gradle" ] && [ ! -f "$PROJ_DIR/build.gradle.kts" ] && [ -d "/project" ]; then
        if [ -f "/project/build.gradle" ] || [ -f "/project/build.gradle.kts" ] || [ -f "/project/app/build.gradle" ] || [ -f "/project/app/build.gradle.kts" ]; then
            PROJ_DIR="/project"
        fi
    fi

    DETECTION_JSON=$(detect-android-project "$PROJ_DIR" --json 2>/dev/null || echo "{}")
    IS_PROJ_ANDROID=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('is_android', False))" 2>/dev/null || echo "False")

    if [ "$IS_PROJ_ANDROID" = "True" ]; then
        # Auto-detect Java if not explicitly set
        if [ -z "$REQ_JAVA" ]; then
            DETECTED_JAVA=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('java_version') or '')" 2>/dev/null || echo "")
            if [ -n "$DETECTED_JAVA" ]; then
                echo "ℹ️  [auto-detect] Detected Java version $DETECTED_JAVA from project configuration"
                REQ_JAVA="$DETECTED_JAVA"
            fi
        fi

        # Auto-detect SDK Platform if not explicitly set
        if [ -z "$REQ_SDK" ]; then
            DETECTED_SDK=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('compile_sdk') or '')" 2>/dev/null || echo "")
            if [ -n "$DETECTED_SDK" ]; then
                echo "ℹ️  [auto-detect] Detected Android compileSdk $DETECTED_SDK from project configuration"
                REQ_SDK="$DETECTED_SDK"
            fi
        fi

        # Auto-detect Build Tools if not explicitly set
        if [ -z "$REQ_BUILD_TOOLS" ]; then
            DETECTED_BT=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('build_tools') or '')" 2>/dev/null || echo "")
            if [ -n "$DETECTED_BT" ]; then
                echo "ℹ️  [auto-detect] Detected Android buildToolsVersion $DETECTED_BT from project configuration"
                REQ_BUILD_TOOLS="$DETECTED_BT"
            fi
        fi

        # Auto-detect NDK if not explicitly set
        if [ -z "$REQ_NDK" ]; then
            DETECTED_NDK=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ndk_version') or '')" 2>/dev/null || echo "")
            if [ -n "$DETECTED_NDK" ]; then
                echo "ℹ️  [auto-detect] Detected Android NDK $DETECTED_NDK from project configuration"
                REQ_NDK="$DETECTED_NDK"
            fi
        fi

        # Auto-detect CMake if not explicitly set
        if [ -z "$REQ_CMAKE" ]; then
            DETECTED_CMAKE=$(echo "$DETECTION_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin).get('cmake_version') or '')" 2>/dev/null || echo "")
            if [ -n "$DETECTED_CMAKE" ]; then
                echo "ℹ️  [auto-detect] Detected Android CMake $DETECTED_CMAKE from project configuration"
                REQ_CMAKE="$DETECTED_CMAKE"
            fi
        fi
    fi
fi

# Apply Java Version
if [ -n "$REQ_JAVA" ]; then
    if [ "$REQ_JAVA" = "17" ] || [ "$REQ_JAVA" = "21" ]; then
        export JAVA_HOME="/opt/jdk-${REQ_JAVA}"
        if command -v switch-jdk >/dev/null 2>&1; then
            # shellcheck source=/dev/null
            source switch-jdk "$REQ_JAVA" >/dev/null 2>&1 || switch-jdk "$REQ_JAVA" >/dev/null 2>&1 || true
        fi
    elif [ "$REQ_JAVA" -lt 17 ] 2>/dev/null; then
        echo "⚠️  [warning] Java $REQ_JAVA is deprecated for AGP 8+/9+. Switching to minimum supported OpenJDK 17."
        export JAVA_HOME="/opt/jdk-17"
        if command -v switch-jdk >/dev/null 2>&1; then
            # shellcheck source=/dev/null
            source switch-jdk 17 >/dev/null 2>&1 || switch-jdk 17 >/dev/null 2>&1 || true
        fi
    fi
fi

# Fast 2s network reachability probe (prevents CI hangs in air-gapped environments)
can_reach_network() {
    if [ "${OFFLINE_MODE:-false}" = "true" ]; then
        return 1
    fi
    local probe_target="https://dl.google.com"
    if [ -n "${NEXUS_URL:-}" ]; then
        probe_target="${NEXUS_URL}"
    elif [ -n "${NEXUS_RUBY_URL:-}" ]; then
        probe_target="${NEXUS_RUBY_URL}"
    fi
    curl -s -m 2 -o /dev/null "$probe_target" 2>/dev/null
}

# Network reachability evaluation & Offline Mode Engine
NETWORK_REACHABLE=true
if [ "${OFFLINE_MODE:-false}" = "true" ]; then
    NETWORK_REACHABLE=false
    echo "🔒 [offline-mode] Explicit OFFLINE_MODE active. Enabling offline build safeguards."
    if [ -d "$GRADLE_DIR/init.d" ]; then
        echo "⚡ [offline-mode] Injected Gradle offline mode fallback (startParameter.offline = true)"
        cat << 'EOF' > "$GRADLE_DIR/init.d/fallback-offline.init.gradle"
gradle.startParameter.offline = true
gradle.projectsLoaded {
    rootProject.logger.warn("⚠️ [hateum/android-ci-box] Strict OFFLINE_MODE active (startParameter.offline=true)")
}
EOF
        export BUNDLE_OFFLINE="true"
    fi
elif ! can_reach_network; then
    NETWORK_REACHABLE=false
    echo "ℹ️  [network-probe] Target mirror/network unreachable. Skipping startup SDK/NDK auto-downloads."
fi

# Apply / Install Android SDK Platform
if [ -n "$REQ_SDK" ] && [ "${AUTO_INSTALL_SDK:-true}" != "false" ]; then
    if [ ! -d "${ANDROID_HOME:-/opt/android-sdk}/platforms/android-${REQ_SDK}" ]; then
        if [ "$NETWORK_REACHABLE" = "true" ]; then
            echo "⬇️  [sdk] Android platform android-${REQ_SDK} not present. Auto-installing..."
            if command -v install-sdk-version >/dev/null 2>&1; then
                install-sdk-version "$REQ_SDK" >/dev/null 2>&1 || true
            fi
        else
            echo "⚠️  [sdk] Android platform android-${REQ_SDK} missing and network unreachable (offline/air-gapped CI). Skipping auto-download."
        fi
    fi
fi

# Apply / Install Android Build-Tools
if [ -n "$REQ_BUILD_TOOLS" ] && [ "${AUTO_INSTALL_SDK:-true}" != "false" ]; then
    if [ ! -d "${ANDROID_HOME:-/opt/android-sdk}/build-tools/${REQ_BUILD_TOOLS}" ]; then
        if [ "$NETWORK_REACHABLE" = "true" ]; then
            echo "⬇️  [sdk] Android build-tools ${REQ_BUILD_TOOLS} not present. Auto-installing..."
            if command -v install-sdk-version >/dev/null 2>&1; then
                install-sdk-version "$REQ_BUILD_TOOLS" >/dev/null 2>&1 || true
            fi
        else
            echo "⚠️  [sdk] Android build-tools ${REQ_BUILD_TOOLS} missing and network unreachable (offline/air-gapped CI). Skipping auto-download."
        fi
    fi
fi

# Apply / Install Android NDK
if [ -n "$REQ_NDK" ] && [ "${AUTO_INSTALL_SDK:-true}" != "false" ]; then
    NDK_BASE_DIR="${ANDROID_HOME:-/opt/android-sdk}/ndk/${REQ_NDK}"
    if [ ! -d "$NDK_BASE_DIR" ]; then
        if [ "$NETWORK_REACHABLE" = "true" ]; then
            echo "⬇️  [ndk] Android NDK ${REQ_NDK} not present. Auto-installing..."
            if command -v install-ndk-version >/dev/null 2>&1; then
                install-ndk-version "$REQ_NDK" "${REQ_CMAKE:-}" >/dev/null 2>&1 || true
            fi
        else
            echo "⚠️  [ndk] Android NDK ${REQ_NDK} missing and network unreachable (offline/air-gapped CI). Skipping auto-download."
        fi
    fi
fi

if [ -n "$REQ_NDK" ] && [ -d "${ANDROID_HOME:-/opt/android-sdk}/ndk/${REQ_NDK}" ]; then
    export ANDROID_NDK_HOME="${ANDROID_HOME:-/opt/android-sdk}/ndk/${REQ_NDK}"
    export ANDROID_NDK_ROOT="${ANDROID_HOME:-/opt/android-sdk}/ndk/${REQ_NDK}"
    export PATH="${ANDROID_NDK_HOME}:${PATH}"
fi

# Apply / Install Android CMake
if [ -n "$REQ_CMAKE" ] && [ "${AUTO_INSTALL_SDK:-true}" != "false" ]; then
    CMAKE_BASE_DIR="${ANDROID_HOME:-/opt/android-sdk}/cmake/${REQ_CMAKE}"
    if [ ! -d "$CMAKE_BASE_DIR" ]; then
        if [ "$NETWORK_REACHABLE" = "true" ]; then
            echo "⬇️  [cmake] Android CMake ${REQ_CMAKE} not present. Auto-installing..."
            "${ANDROID_HOME:-/opt/android-sdk}/cmdline-tools/latest/bin/sdkmanager" "cmake;${REQ_CMAKE}" >/dev/null 2>&1 || true
        else
            echo "⚠️  [cmake] Android CMake ${REQ_CMAKE} missing and network unreachable (offline/air-gapped CI). Skipping auto-download."
        fi
    fi
fi

if [ -n "$REQ_CMAKE" ] && [ -d "${ANDROID_HOME:-/opt/android-sdk}/cmake/${REQ_CMAKE}/bin" ]; then
    export PATH="${ANDROID_HOME:-/opt/android-sdk}/cmake/${REQ_CMAKE}/bin:${PATH}"
fi

# ------------------------------------------------------------------------------
# 1. Gradle CI Performance Optimization Defaults
# ------------------------------------------------------------------------------
GRADLE_PROP_FILE="$GRADLE_DIR/gradle.properties"

if [ ! -f "$GRADLE_PROP_FILE" ]; then
    cat <<EOF > "$GRADLE_PROP_FILE"
# ==============================================================================
# Pre-configured Gradle CI Performance Optimizations
# ==============================================================================
org.gradle.daemon=false
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.vfs.watch=false
org.gradle.jvmargs=${GRADLE_JVMARGS:--Xmx4g -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:+TieredCompilation -Dfile.encoding=UTF-8}

# Gradle Managed Devices (GMD) Headless & CI Automation
android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect
android.testoptions.manageddevices.emulator.showKernelLogging=true
android.experimental.testoptions.manageddevices.maxconcurrentdevices=1
EOF
fi

if [ "${ENABLE_CI_OPTIMIZATIONS:-true}" != "false" ] && [ -d "$GRADLE_DIR/init.d" ]; then
    cat << 'EOF' > "$GRADLE_DIR/init.d/ci-optimizations.init.gradle"
allprojects {
    tasks.withType(JavaCompile).configureEach {
        options.fork = true
        options.encoding = 'UTF-8'
    }
}
gradle.projectsLoaded {
    rootProject.logger.info("⚡ [hateum/android-ci-box] CI Optimizations active: parallel=true, buildCache=true, daemon=false")
}
EOF
fi

# ------------------------------------------------------------------------------
# 2. Enterprise Corporate CA Certificates Auto-Detection & Injection
# ------------------------------------------------------------------------------
CERT_DIRS=("/certificates" "/usr/local/share/ca-certificates")
CA_IMPORTED=0

for cdir in "${CERT_DIRS[@]}"; do
    if [ -d "$cdir" ]; then
        for cert in "$cdir"/*.crt "$cdir"/*.cer "$cdir"/*.pem; do
            [ -f "$cert" ] || continue
            cert_name=$(basename "$cert")
            if [ "$cdir" != "/usr/local/share/ca-certificates" ]; then
                cp -f "$cert" /usr/local/share/ca-certificates/ 2>/dev/null || true
            fi
            if [ -n "$JAVA_HOME" ] && [ -w "$JAVA_HOME/lib/security/cacerts" ]; then
                keytool -importcert -noprompt -trustcacerts \
                    -keystore "$JAVA_HOME/lib/security/cacerts" \
                    -storepass changeit \
                    -alias "corp-ca-${cert_name}" \
                    -file "$cert" >/dev/null 2>&1 || true
            fi
            CA_IMPORTED=1
        done
    fi
done

# Dynamic CA download from URL if provided
TARGET_CA_URL="${CORPORATE_CA_URL:-${CA_CERT_URL:-}}"
if [ -n "$TARGET_CA_URL" ]; then
    curl -fsSL -k "$TARGET_CA_URL" -o /usr/local/share/ca-certificates/corporate-url-ca.crt 2>/dev/null || true
    if [ -f /usr/local/share/ca-certificates/corporate-url-ca.crt ]; then
        CA_IMPORTED=1
        if [ -n "$JAVA_HOME" ] && [ -w "$JAVA_HOME/lib/security/cacerts" ]; then
            keytool -importcert -noprompt -trustcacerts \
                -keystore "$JAVA_HOME/lib/security/cacerts" \
                -storepass changeit \
                -alias "corp-url-ca" \
                -file /usr/local/share/ca-certificates/corporate-url-ca.crt >/dev/null 2>&1 || true
        fi
    fi
fi

if [ "$CA_IMPORTED" -eq 1 ] && [ "$(id -u)" -eq 0 ]; then
    update-ca-certificates >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 3. Enterprise Corporate Proxy Auto-Detection
# ------------------------------------------------------------------------------
RAW_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}"
if [ -n "$RAW_PROXY" ] && [ -w "$GRADLE_PROP_FILE" ]; then
    CLEAN_PROXY="${RAW_PROXY#*://}"
    PROXY_HOST=$(echo "$CLEAN_PROXY" | cut -d: -f1)
    PROXY_PORT=$(echo "$CLEAN_PROXY" | cut -d: -f2 | cut -d/ -f1)
    NON_PROXY="${NO_PROXY:-${no_proxy:-"localhost,127.0.0.1"}}"
    NON_PROXY_JAVA=$(echo "$NON_PROXY" | tr ',' '|')

    cat <<EOF >> "$GRADLE_PROP_FILE"
systemProp.http.proxyHost=$PROXY_HOST
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=$PROXY_HOST
systemProp.https.proxyPort=$PROXY_PORT
systemProp.http.nonProxyHosts=$NON_PROXY_JAVA
systemProp.https.nonProxyHosts=$NON_PROXY_JAVA
EOF
fi

# ------------------------------------------------------------------------------
# 4. Enterprise Nexus / Artifactory Multi-Repository & Auto-Derivation Engine
# ------------------------------------------------------------------------------
ALL_NEXUS_INPUT="${NEXUS_URLS:-${NEXUS_URL:-${NEXUS_BASE_URL:-${INTERNAL_MAVEN_URL:-${ARTIFACTORY_URL:-${MAVEN_REPO_URL:-}}}}}}"

if [ -n "$ALL_NEXUS_INPUT" ] && [ -d "$GRADLE_DIR/init.d" ]; then
    CLEAN_INPUT=$(echo "$ALL_NEXUS_INPUT" | tr ',' ' ')
    PARSED_REPOS=()
    PRIMARY_MIRROR=""

    for raw_url in $CLEAN_INPUT; do
        url="${raw_url%/}"
        [ -z "$url" ] && continue

        if [[ "$url" != *"/repository/"* ]] && [[ "$url" != *"/artifactory/"* ]]; then
            derived_group="${url}/repository/maven-public/"
            derived_releases="${url}/repository/maven-releases/"
            PARSED_REPOS+=("$derived_group")
            PARSED_REPOS+=("$derived_releases")
            [ -z "$PRIMARY_MIRROR" ] && PRIMARY_MIRROR="$derived_group"
        else
            PARSED_REPOS+=("$url")
            [ -z "$PRIMARY_MIRROR" ] && PRIMARY_MIRROR="$url"
        fi
    done

    MIRROR_USER="${NEXUS_USER:-${ARTIFACTORY_USER:-}}"
    MIRROR_PASS="${NEXUS_PASSWORD:-${ARTIFACTORY_PASSWORD:-}}"
    CREDENTIALS_BLOCK=""
    if [ -n "$MIRROR_USER" ] && [ -n "$MIRROR_PASS" ]; then
        CREDENTIALS_BLOCK="credentials { username = '$MIRROR_USER'; password = '$MIRROR_PASS' }"
    fi

    GROOVY_REPOS_CODE=""
    for repo_url in "${PARSED_REPOS[@]}"; do
        GROOVY_REPOS_CODE="${GROOVY_REPOS_CODE}
            maven {
                url = uri('$repo_url')
                $CREDENTIALS_BLOCK
            }"
    done

    cat <<EOF > "$GRADLE_DIR/init.d/nexus-mirror.init.gradle"
allprojects {
    buildscript {
        repositories {
            all { ArtifactRepository repo ->
                if (repo instanceof MavenArtifactRepository) {
                    def urlStr = repo.url.toString()
                    if (urlStr.contains("dl.google.com") || urlStr.contains("repo.maven.apache.org") || urlStr.contains("plugins.gradle.org")) {
                        repo.url = uri('$PRIMARY_MIRROR')
                        $CREDENTIALS_BLOCK
                    }
                }
            }
            $GROOVY_REPOS_CODE
        }
    }
    repositories {
        all { ArtifactRepository repo ->
            if (repo instanceof MavenArtifactRepository) {
                def urlStr = repo.url.toString()
                if (urlStr.contains("dl.google.com") || urlStr.contains("repo.maven.apache.org") || urlStr.contains("plugins.gradle.org")) {
                    repo.url = uri('$PRIMARY_MIRROR')
                    $CREDENTIALS_BLOCK
                }
            }
        }
        $GROOVY_REPOS_CODE
    }
}
EOF
fi

# ------------------------------------------------------------------------------
# 4.1 Enterprise Ruby & Fastlane Gem Mirror (Bundler & RubyGems)
# Priority: Explicit NEXUS_RUBY_URL / RUBYGEM_MIRROR_URL / RUBY_MIRROR_URL
# Fallback: Auto-derivation from NEXUS_URL if NEXUS_RUBY_URL is not provided
# ------------------------------------------------------------------------------
RUBY_MIRROR_TARGET="${NEXUS_RUBY_URL:-${RUBYGEM_MIRROR_URL:-${RUBY_MIRROR_URL:-}}}"
if [ -z "$RUBY_MIRROR_TARGET" ] && [ -n "${NEXUS_URL:-}" ]; then
    NEXUS_BASE="${NEXUS_URL%/}"
    if [[ "$NEXUS_BASE" == *"/repository/"* ]]; then
        NEXUS_PREFIX="${NEXUS_BASE%%/repository/*}"
        RUBY_MIRROR_TARGET="${NEXUS_PREFIX}/repository/rubygems-group/"
    elif [[ "$NEXUS_BASE" == *"/artifactory/"* ]]; then
        NEXUS_PREFIX="${NEXUS_BASE%%/artifactory/*}"
        RUBY_MIRROR_TARGET="${NEXUS_PREFIX}/artifactory/api/gems/gems/"
    else
        RUBY_MIRROR_TARGET="${NEXUS_BASE}/repository/rubygems-group/"
    fi
fi

if [ -n "$RUBY_MIRROR_TARGET" ]; then
    echo "💎 [ruby-mirror] Active RubyGems mirror: ${RUBY_MIRROR_TARGET}"

    # Global Bundler configuration file with universal permissions
    mkdir -p /home/runner/.bundle /root/.bundle 2>/dev/null || true
    chmod -R 777 /home/runner/.bundle 2>/dev/null || true
    if command -v bundle >/dev/null 2>&1; then
        bundle config set --global mirror.https://rubygems.org "${RUBY_MIRROR_TARGET}" 2>/dev/null || true
        bundle config set --global mirror.https://rubygems.org/ "${RUBY_MIRROR_TARGET}" 2>/dev/null || true

        RUBY_AUTH_USER="${NEXUS_RUBY_USER:-${NEXUS_USER:-}}"
        RUBY_AUTH_PASS="${NEXUS_RUBY_PASSWORD:-${NEXUS_PASSWORD:-}}"
        if [ -n "$RUBY_AUTH_USER" ] && [ -n "$RUBY_AUTH_PASS" ]; then
            bundle config set --global "${RUBY_MIRROR_TARGET}" "${RUBY_AUTH_USER}:${RUBY_AUTH_PASS}" 2>/dev/null || true
        fi
    fi

    # RubyGems CLI source
    if command -v gem >/dev/null 2>&1; then
        gem sources --add "${RUBY_MIRROR_TARGET}" 2>/dev/null || true
        gem sources --remove https://rubygems.org/ 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 5. Enterprise Gradle Shared Remote Build Cache (HttpBuildCache)
# Active if GRADLE_BUILD_CACHE_URL or GRADLE_REMOTE_CACHE_URL is defined
# ------------------------------------------------------------------------------
REMOTE_CACHE_URL="${GRADLE_BUILD_CACHE_URL:-${GRADLE_REMOTE_CACHE_URL:-}}"
if [ -n "$REMOTE_CACHE_URL" ] && [ -d "$GRADLE_DIR/init.d" ]; then
    CACHE_USER="${GRADLE_BUILD_CACHE_USER:-${NEXUS_USER:-}}"
    CACHE_PASS="${GRADLE_BUILD_CACHE_PASSWORD:-${NEXUS_PASSWORD:-}}"
    CACHE_PUSH="${GRADLE_BUILD_CACHE_PUSH:-true}"
    CACHE_CREDS=""
    if [ -n "$CACHE_USER" ] && [ -n "$CACHE_PASS" ]; then
        CACHE_CREDS="credentials { username = '$CACHE_USER'; password = '$CACHE_PASS' }"
    fi

    cat <<EOF > "$GRADLE_DIR/init.d/remote-build-cache.init.gradle"
import org.gradle.caching.http.HttpBuildCache

settingsEvaluated { settings ->
    settings.buildCache {
        local {
            enabled = true
        }
        remote(HttpBuildCache) {
            url = uri('$REMOTE_CACHE_URL')
            push = $CACHE_PUSH
            $CACHE_CREDS
        }
    }
}
EOF
fi

# ------------------------------------------------------------------------------
# 6. Android Emulator, KVM & Workspaces Permissions Compatibility
# ------------------------------------------------------------------------------
AVD_DIR="${ANDROID_AVD_HOME:-/home/runner/.android/avd}"
mkdir -p /builds /project /certificates "$AVD_DIR" 2>/dev/null || true
chmod 777 /opt /opt/default-jdk /builds /project /certificates 2>/dev/null || true
chmod -R 777 "$GRADLE_DIR" "$AVD_DIR" 2>/dev/null || true
if [ -e /dev/kvm ] && [ "$(id -u)" -eq 0 ]; then
    chmod 666 /dev/kvm 2>/dev/null || true
fi

# Execute CMD / CI command
exec "$@"
