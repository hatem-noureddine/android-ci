# Enterprise CI/CD Pipeline Templates for `hateum/android-ci-box`

Pre-configured, battle-tested, and security-hardened pipeline configurations for modern CI/CD engines.

---

## Available CI Templates

| CI Platform | Template Path | Description | Key Features |
| :--- | :--- | :--- | :--- |
| **GitLab CI** | [`gitlab/.gitlab-ci.yml`](gitlab/.gitlab-ci.yml) | Complete multi-stage pipeline | Dual-mode proxy, Gradle cache, parallel lint & unit tests, release artifacts |
| **GitLab Component** | [`gitlab/templates/android-ci.yml`](gitlab/templates/android-ci.yml) | GitLab 16+ Component Catalog | Parameterized inputs (`image_tag`, `java_version`, `gradle_tasks`) |
| **Jenkins** | [`jenkins/Jenkinsfile`](jenkins/Jenkinsfile) | Declarative Jenkins Pipeline | Rootless execution (`-u 1000:1000`), Gradle volume cache, JUnit test reporting |
| **Bitbucket** | [`bitbucket/bitbucket-pipelines.yml`](bitbucket/bitbucket-pipelines.yml) | Native Bitbucket Pipelines | Custom Gradle cache definitions, branch & PR workflows |
| **GitHub Actions** | [`github/android-ci-workflow.yml`](github/android-ci-workflow.yml) | Reusable `workflow_call` | Drop-in workflow callable across your entire GitHub organization |

---

## Choosing Image Variants: `:slim` vs `:latest`

For most continuous integration pipelines, we strongly recommend using the **`:slim`** variant:

```yaml
image: hateum/android-ci-box:slim
```

- **`:slim`** (~2.2 GB compressed): Contains all Android SDKs, build-tools, Java 17/21, NDK hooks, Fastlane, and CLI utilities. Ideal for compilation, linting, unit tests, and APK/AAB signing. Downloads **~1.3 GB less** data per worker node.
- **`:latest` / `:full`** (~3.5 GB compressed): Adds the Linux Android Emulator and system image support for headless instrumented UI tests on `x86_64` (`amd64`) machines with KVM acceleration.

---

## Corporate Proxy & Offline Mirror Configuration

When deploying inside enterprise networks (behind a forward proxy or private artifact repository like Nexus / Artifactory), you do **not** need to modify your build scripts or Dockerfile. Simply supply your enterprise environment variables to the CI job or runner:

```yaml
variables:
  HTTP_PROXY: "http://proxy.internal:8080"
  HTTPS_PROXY: "http://proxy.internal:8080"
  NO_PROXY: "localhost,127.0.0.1,.internal"
  NEXUS_URL: "https://nexus.corp.internal/repository/maven-public/"
  CORPORATE_CA_URL: "https://nexus.corp.internal/pki/corp-ca.crt"
```

The container's [`entrypoint.sh`](../entrypoint.sh) will automatically:
1. Download and import `CORPORATE_CA_URL` into the system truststore and both Java 17 and Java 21 `cacerts`.
2. Configure `~/.gradle/gradle.properties` with proxy host, port, and non-proxy hosts.
3. Inject the `NEXUS_URL` mirror initialization script into `~/.gradle/init.d/nexus-mirror.gradle`.
