# Enterprise Networking, Proxies & Corporate CA Certificates

This guide explains how `hateum/android-ci-box` dynamically handles enterprise network constraints (corporate HTTP/HTTPS proxies, SSL inspection, custom CA truststores, and internal artifact mirrors).

---

## 1. Zero-Friction Network Engine

The container operates in **Dual-Mode**:
1. **Public Internet**: Zero configuration required. Gradle, Android CLI, and Curl connect directly.
2. **Corporate Intranet**: When standard enterprise environment variables or certificates are detected, `entrypoint.sh` automatically configures Java truststores and Gradle system properties before running any user commands.

---

## 2. Supported Environment Variables

| Variable | Example | Effect |
| :--- | :--- | :--- |
| `HTTP_PROXY` / `http_proxy` | `http://proxy.corp.internal:8080` | Injected into Gradle `systemProp.http.proxyHost` and `systemProp.http.proxyPort`. |
| `HTTPS_PROXY` / `https_proxy` | `http://proxy.corp.internal:8080` | Injected into Gradle `systemProp.https.proxyHost` and `systemProp.https.proxyPort`. |
| `NO_PROXY` / `no_proxy` | `localhost,127.0.0.1,.corp.internal` | Injected into `systemProp.http.nonProxyHosts` (converted from commas to pipe `\|` notation). |
| `NEXUS_URL` / `ARTIFACTORY_URL` | `https://nexus.corp.internal/repository/maven-public/` | Configured as primary Gradle mirror repository. |
| `CORPORATE_CA_URL` | `http://pki.corp.internal/ca.crt` | Downloaded and imported into Java and OS truststores during container startup. |

---

## 3. Mounting Custom SSL / TLS Certificates

If your organization performs SSL inspection (e.g., Zscaler, Palo Alto, Netskope):

Mount your corporate PEM or CRT certificates into `/certificates/`:

```bash
docker run --rm \
  -v /path/to/my-corporate-root-ca.crt:/certificates/corp.crt:ro \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew assembleRelease
```

### Automatic Import Flow in `entrypoint.sh`:
1. Searches `/certificates/` for `*.crt` and `*.pem` files.
2. Copies certificates into `/usr/local/share/ca-certificates/` and runs `update-ca-certificates`.
3. Imports each certificate into OpenJDK 17 and OpenJDK 21 `cacerts` keystores using Java `keytool`.
4. Fixes permissions so rootless non-root users (`runner`) have full read access to the updated truststores.

---

## 4. Diagnostics with `ci-doctor`

To verify that your proxy and certificates are active before initiating builds:

```bash
ci-doctor
```

Look for the **Enterprise & Corporate Network Configuration** section in the output:
- `HTTP Proxy: Active (proxy.corp.internal:8080)`
- `HTTPS Proxy: Active (proxy.corp.internal:8080)`
- `Corporate Certificates: 1 certificate imported`
- `Network Connectivity Check: SUCCESS (Google Maven reachable)`
