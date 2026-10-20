#!/bin/bash
set -e

# ==============================================================================
# Universal Dual-Mode Network & CI Auto-Detection Engine
# Seamless execution in both standard unrestricted Internet and enterprise intranets
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Enterprise Corporate CA Certificates Auto-Detection & Injection
# Active only if custom certificates are provided (volume mount or environment)
# In standard internet mode, default Ubuntu/Mozilla CA certificates are untouched.
# ------------------------------------------------------------------------------
CERT_DIRS=("/certificates" "/usr/local/share/ca-certificates")
CA_IMPORTED=0

for cdir in "${CERT_DIRS[@]}"; do
    if [ -d "$cdir" ]; then
        for cert in "$cdir"/*.crt "$cdir"/*.cer "$cdir"/*.pem; do
            [ -f "$cert" ] || continue
            cert_name=$(basename "$cert")
            # Copy to system ca-certificates directory if mounted elsewhere
            if [ "$cdir" != "/usr/local/share/ca-certificates" ]; then
                cp -f "$cert" /usr/local/share/ca-certificates/ 2>/dev/null || true
            fi
            # Import into Java cacerts truststore for Gradle / Kotlin compiler
            if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/lib/security/cacerts" ]; then
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

# If CA URL provided in environment (e.g. CORPORATE_CA_URL or CA_CERT_URL)
TARGET_CA_URL="${CORPORATE_CA_URL:-${CA_CERT_URL:-}}"
if [ -n "$TARGET_CA_URL" ]; then
    curl -fsSL -k "$TARGET_CA_URL" -o /usr/local/share/ca-certificates/corporate-url-ca.crt 2>/dev/null || true
    if [ -f /usr/local/share/ca-certificates/corporate-url-ca.crt ]; then
        CA_IMPORTED=1
        if [ -n "$JAVA_HOME" ] && [ -f "$JAVA_HOME/lib/security/cacerts" ]; then
            keytool -importcert -noprompt -trustcacerts \
                -keystore "$JAVA_HOME/lib/security/cacerts" \
                -storepass changeit \
                -alias "corp-url-ca" \
                -file /usr/local/share/ca-certificates/corporate-url-ca.crt >/dev/null 2>&1 || true
        fi
    fi
fi

if [ "$CA_IMPORTED" -eq 1 ]; then
    update-ca-certificates >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 2. Enterprise Corporate Proxy Auto-Detection
# Active only if HTTP_PROXY or HTTPS_PROXY is defined.
# If no proxy variables exist, no proxy configuration is written (pure direct internet).
# ------------------------------------------------------------------------------
RAW_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}"
if [ -n "$RAW_PROXY" ]; then
    mkdir -p /root/.gradle
    CLEAN_PROXY=$(echo "$RAW_PROXY" | sed -e 's|^[^/]*//||')
    PROXY_HOST=$(echo "$CLEAN_PROXY" | cut -d: -f1)
    PROXY_PORT=$(echo "$CLEAN_PROXY" | cut -d: -f2 | cut -d/ -f1)
    NON_PROXY="${NO_PROXY:-${no_proxy:-"localhost,127.0.0.1"}}"
    NON_PROXY_JAVA=$(echo "$NON_PROXY" | tr ',' '|')

    cat <<EOF >> /root/.gradle/gradle.properties
systemProp.http.proxyHost=$PROXY_HOST
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=$PROXY_HOST
systemProp.https.proxyPort=$PROXY_PORT
systemProp.http.nonProxyHosts=$NON_PROXY_JAVA
systemProp.https.nonProxyHosts=$NON_PROXY_JAVA
EOF
fi

# ------------------------------------------------------------------------------
# 3. Enterprise Nexus / Artifactory Multi-URL & Auto-Derivation Engine
# - Automatically detects base URL (e.g. https://nexus.corp) and derives
#   standard sub-repositories (/repository/maven-public/ and /repository/maven-releases/)
# - Supports multiple URLs (comma or space separated)
# - In standard internet mode, Gradle directly accesses official Google/Maven repos.
# ------------------------------------------------------------------------------
ALL_NEXUS_INPUT="${NEXUS_URLS:-${NEXUS_URL:-${INTERNAL_MAVEN_URL:-${ARTIFACTORY_URL:-${MAVEN_REPO_URL:-}}}}}"

if [ -n "$ALL_NEXUS_INPUT" ]; then
    mkdir -p /root/.gradle/init.d

    CLEAN_INPUT=$(echo "$ALL_NEXUS_INPUT" | tr ',' ' ')
    PARSED_REPOS=()
    PRIMARY_MIRROR=""

    for raw_url in $CLEAN_INPUT; do
        url="${raw_url%/}"
        [ -z "$url" ] && continue

        # If bare base URL passed (without /repository/ or /artifactory/), auto-derive standard repos
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

    # Authentication credentials block if provided
    MIRROR_USER="${NEXUS_USER:-${ARTIFACTORY_USER:-}}"
    MIRROR_PASS="${NEXUS_PASSWORD:-${ARTIFACTORY_PASSWORD:-}}"
    CREDENTIALS_BLOCK=""
    if [ -n "$MIRROR_USER" ] && [ -n "$MIRROR_PASS" ]; then
        CREDENTIALS_BLOCK="credentials { username = '$MIRROR_USER'; password = '$MIRROR_PASS' }"
    fi

    # Build Groovy repo definitions list
    GROOVY_REPOS_CODE=""
    for repo_url in "${PARSED_REPOS[@]}"; do
        GROOVY_REPOS_CODE="${GROOVY_REPOS_CODE}
            maven {
                url = uri('$repo_url')
                $CREDENTIALS_BLOCK
            }"
    done

    cat <<EOF > /root/.gradle/init.d/nexus-mirror.init.gradle
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
# 4. Workspaces & CI Runners Compatibility
# Ensures frictionless permissions on GitLab Runner (/builds) and standard mounts
# ------------------------------------------------------------------------------
mkdir -p /builds /project /certificates
chmod 777 /builds /project /certificates 2>/dev/null || true
chmod -R 777 /root/.gradle 2>/dev/null || true

# Execute CMD / CI command
exec "$@"
