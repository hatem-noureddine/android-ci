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
org.gradle.jvmargs=${GRADLE_JVMARGS:--Xmx4g -XX:+UseG1GC -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Dfile.encoding=UTF-8}
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
ALL_NEXUS_INPUT="${NEXUS_URLS:-${NEXUS_URL:-${INTERNAL_MAVEN_URL:-${ARTIFACTORY_URL:-${MAVEN_REPO_URL:-}}}}}"

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
# 6. Workspaces Permissions Compatibility
# ------------------------------------------------------------------------------
mkdir -p /builds /project /certificates 2>/dev/null || true
chmod 777 /builds /project /certificates 2>/dev/null || true
chmod -R 777 "$GRADLE_DIR" 2>/dev/null || true

# Execute CMD / CI command
exec "$@"
