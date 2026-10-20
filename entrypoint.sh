#!/bin/bash
set -e

# ==============================================================================
# Android CI Auto-Detection Engine for Internal Networks & GitLab Runner
# ==============================================================================

# 1. Corporate CA Certificates Auto-Import into Linux & Java truststores
CERT_DIRS=("/certificates" "/usr/local/share/ca-certificates")
CA_IMPORTED=0

for cdir in "${CERT_DIRS[@]}"; do
    if [ -d "$cdir" ]; then
        for cert in "$cdir"/*.crt "$cdir"/*.cer "$cdir"/*.pem; do
            [ -f "$cert" ] || continue
            cert_name=$(basename "$cert")
            # Copy to system ca-certificates directory if mounted elsewhere
            if [ "$cdir" != "/usr/local/share/ca-certificates" ]; then
                cp -f "$cert" /usr/local/share/ca-certificates/
            fi
            # Import certificate into Java's cacerts truststore
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

if [ "$CA_IMPORTED" -eq 1 ]; then
    update-ca-certificates >/dev/null 2>&1 || true
fi

# Support dynamic CA download from URL if provided (e.g. CORPORATE_CA_URL)
if [ -n "$CORPORATE_CA_URL" ]; then
    curl -fsSL -k "$CORPORATE_CA_URL" -o /usr/local/share/ca-certificates/corporate-ca.crt 2>/dev/null || true
    if [ -f /usr/local/share/ca-certificates/corporate-ca.crt ]; then
        update-ca-certificates >/dev/null 2>&1 || true
        keytool -importcert -noprompt -trustcacerts \
            -keystore "$JAVA_HOME/lib/security/cacerts" \
            -storepass changeit \
            -alias "corporate-url-ca" \
            -file /usr/local/share/ca-certificates/corporate-ca.crt >/dev/null 2>&1 || true
    fi
fi

# 2. HTTP / HTTPS Corporate Proxy Auto-Configuration for Gradle
mkdir -p /root/.gradle /root/.gradle/init.d

RAW_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy}}}}"
if [ -n "$RAW_PROXY" ]; then
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

# 3. Nexus / Artifactory Internal Mirror Auto-Configuration
TARGET_MIRROR="${NEXUS_URL:-${INTERNAL_MAVEN_URL:-${MAVEN_REPO_URL}}}"
if [ -n "$TARGET_MIRROR" ]; then
    CREDENTIALS_BLOCK=""
    if [ -n "$NEXUS_USER" ] && [ -n "$NEXUS_PASSWORD" ]; then
        CREDENTIALS_BLOCK="credentials { username = '$NEXUS_USER'; password = '$NEXUS_PASSWORD' }"
    fi

    cat <<EOF > /root/.gradle/init.d/nexus-mirror.init.gradle
allprojects {
    buildscript {
        repositories {
            all { ArtifactRepository repo ->
                if (repo instanceof MavenArtifactRepository) {
                    repo.url = uri('$TARGET_MIRROR')
                    $CREDENTIALS_BLOCK
                }
            }
        }
    }
    repositories {
        all { ArtifactRepository repo ->
            if (repo instanceof MavenArtifactRepository) {
                repo.url = uri('$TARGET_MIRROR')
                $CREDENTIALS_BLOCK
            }
        }
    }
}
EOF
fi

# 4. GitLab Runner directory permissions compatibility
mkdir -p /builds /project
chmod 777 /builds /project 2>/dev/null || true
chmod -R 777 /root/.gradle 2>/dev/null || true

# Execute CMD / GitLab CI command
exec "$@"
