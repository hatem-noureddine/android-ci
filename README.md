# Android CI/CD Build Box (`hateum/android-ci-box`)

[![Docker Hub](https://img.shields.io/docker/pulls/hateum/android-ci-box?style=flat-square&logo=docker)](https://hub.docker.com/r/hateum/android-ci-box)
[![Docker Image Size](https://img.shields.io/docker/image-size/hateum/android-ci-box/latest?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Multi-Arch](https://img.shields.io/badge/architecture-amd64%20%7C%20arm64-blue?style=flat-square)](https://hub.docker.com/r/hateum/android-ci-box)
[![Gradle Version](https://img.shields.io/badge/Gradle-9.8.2-02303A?style=flat-square&logo=gradle)](https://gradle.org)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-API%2035%20%7C%2036%20%7C%2037-34A853?style=flat-square&logo=android)](https://developer.android.com)
[![Java](https://img.shields.io/badge/OpenJDK-17%20%7C%2021%20(Default)-ED8B00?style=flat-square&logo=openjdk)](https://openjdk.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

Une image Docker moderne, ultra-rapide et sécurisée conçue spécifiquement pour les pipelines d'**Intégration et Déploiement Continus (CI/CD) Android** (**GitLab Runner**, **GitHub Actions**, **Jenkins**, **Bitbucket Pipelines**).

Elle intègre un **moteur réseau universel dual-mode** qui fonctionne clé en main sur **Internet standard (sans restriction)** tout en s'adaptant automatiquement aux **réseaux d'entreprise internes sécurisés** (miroirs Nexus / Artifactory, inspection SSL / certificats CA d'entreprise, proxies HTTP/HTTPS).

---

## 🏛️ Architecture de l'Image

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                       hateum/android-ci-box:latest                            │
├───────────────────────────────────────────────────────────────────────────────┤
│  OS de Base : Ubuntu 24.04 LTS (Noble) | Multi-Arch: linux/amd64, linux/arm64 │
├───────────────────────────────────────────────────────────────────────────────┤
│  ☕ Runtimes Java     : OpenJDK 21 (Défaut) + OpenJDK 17 (Bascule instantanée) │
│  🐘 Moteur Gradle     : Gradle 9.8.2 (Standalone & Support Wrapper)          │
│  📱 Android SDK       : APIs 35, 36, 37 + Build-Tools 35.0.0, 36.0.0, 37.0.0 │
│  🚀 Déploiement       : Fastlane, Bundletool 1.18.3, GitHub CLI (gh)         │
│  🐍 Scripts CI        : Python 3 & Pip (sans blocage PEP 668), Ruby          │
│  🩺 Autodiagnostic    : Utilitaire CLI 'ci-doctor' intégré                    │
├───────────────────────────────────────────────────────────────────────────────┤
│                      🌐 MOTEUR RÉSEAU UNIVERSEL DUAL-MODE                     │
│  Mode 1 (Internet)    : Accès direct officiel Google & Maven (0 latence)      │
│  Mode 2 (Entreprise)  : Auto-import CA SSL + Auto-config Proxy + Auto Nexus   │
├───────────────────────────────────────────────────────────────────────────────┤
│                      🛡️ SÉCURITÉ UNIVERSELLE ROOT & NON-ROOT                  │
│  Support complet UID arbitraire (OpenShift, Kubernetes durci, UID 1000:0)     │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## ⚡ Démarrage Rapide en 60 Secondes

### 1. Compiler une application Android en local (One-Liner)
Montez le dossier de votre projet Android dans `/project` :
```bash
docker run --rm \
  -v "$(pwd)":/project \
  -v "$HOME/.gradle":/home/runner/.gradle \
  -w /project \
  hateum/android-ci-box:latest \
  ./gradlew assembleRelease
```

### 2. Lancer un shell interactif pour déboguer
```bash
docker run -it --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  bash
```

### 3. Lancer l'outil d'autodiagnostic en 1 seconde
```bash
docker run --rm hateum/android-ci-box:latest ci-doctor
```

---

## 📊 Tableau Récapitulatif des Composants et Versions

| Composant | Version Installée | Détails / Rôle |
| :--- | :--- | :--- |
| **Système d'exploitation** | **Ubuntu 24.04 LTS** (Noble) | Base LTS récente avec support multi-architecture natif (`amd64` / `arm64`). |
| **Gradle Standalone** | **9.8.2** (Dernière stable) | Installé dans `/opt/gradle` et disponible directement via la commande `gradle`. |
| **Java JDKs** | **OpenJDK 21** (Défaut) & **17** | Versions Headless optimisées. Basculable via la commande `switch-jdk 17`. |
| **Android SDK Platforms** | **API 35, 36, 37** (Toutes stables) | Android 15, Android 16 (Baklava) et Android 17 (Cinnamon Bun). |
| **Android Build-Tools** | **`35.0.0`, `36.0.0`, `37.0.0`** | Outils de compilation officiels Google pour API 35, 36 et 37. |
| **Command-Line Tools** | **`15859902`** | Derniers outils officiels Google `sdkmanager` avec licences pré-acceptées. |
| **Bundletool (Google)** | **`1.18.3`** | Outil officiel de génération d'APKs universels à partir d'AAB (`bundletool`). |
| **Fastlane & Bundler** | **`2.441.0+`** (Dernière version) | Automatisation complète des builds et déploiements Play Store. |
| **Python & Pip** | **Python 3.12+** | Pré-configuré avec `break-system-packages = true` pour les scripts CI. |
| **CLI Utilitaires** | **GitHub CLI (`gh`)**, Git, Git LFS | Outils pour créer des releases GitHub et gérer les assets volumineux. |
| **Outil de diagnostic** | **`ci-doctor`** | Rapport visuel complet de l'état du conteneur et tests de connectivité. |

---

## ⚙️ Guide des Variables d'Environnement (Référence Complète)

Toutes les configurations d'entreprise s'activent **automatiquement** dès qu'une des variables ci-dessous est présente. Si aucune variable n'est définie, le conteneur fonctionne en **accès Internet direct sans friction**.

| Variable | Description | Exemple |
| :--- | :--- | :--- |
| `NEXUS_URL` | URL de base ou URL de groupe de votre serveur Nexus / Artifactory. Dérive automatiquement `/repository/maven-public/` et `/repository/maven-releases/`. | `https://nexus.entreprise.corp` |
| `NEXUS_URLS` | Liste d'URLs de dépôts Nexus multiples séparées par des virgules. | `https://nexus.corp/repository/maven-public, https://nexus.corp/repository/libs` |
| `NEXUS_USER` | *(Optionnel)* Nom d'utilisateur pour l'authentification Nexus. | `ci-runner-user` |
| `NEXUS_PASSWORD` | *(Optionnel)* Mot de passe ou token d'accès Nexus. | `$NEXUS_CI_TOKEN` |
| `CORPORATE_CA_URL`| *(Optionnel)* URL pour télécharger à chaud un certificat d'autorité racine d'entreprise. | `https://pki.corp/certs/corporate-root-ca.crt` |
| `HTTPS_PROXY` | Proxy HTTPS de votre entreprise (injecté automatiquement dans `gradle.properties`). | `http://proxy.corp:8080` |
| `HTTP_PROXY` | Proxy HTTP de votre entreprise. | `http://proxy.corp:8080` |
| `NO_PROXY` | Hôtes ou domaines exemptés de proxy. | `localhost,127.0.0.1,.corp,.local` |
| `GRADLE_JVMARGS` | *(Optionnel)* Surcharge des options mémoire JVM de Gradle. | `-Xmx6g -XX:+UseG1GC` (Défaut: `-Xmx4g`) |
| `GRADLE_BUILD_CACHE_URL` | *(Optionnel)* URL du cache de build distant partagé HTTP (Gradle Remote Build Cache). | `https://cache.entreprise.corp/cache/` |
| `GRADLE_BUILD_CACHE_PUSH`| *(Optionnel)* Autorise l'envoi vers le cache distant (`true`/`false`). | `true` (Défaut: `true`) |
| `GRADLE_BUILD_CACHE_USER`| *(Optionnel)* Utilisateur pour le cache de build distant. | `ci-cache-user` |
| `GRADLE_BUILD_CACHE_PASSWORD`| *(Optionnel)* Mot de passe ou token pour le cache distant. | `$CACHE_TOKEN` |
| `JAVA_HOME` | Chemin du JDK actif. | `/opt/default-jdk` (Défaut: JDK 21) |
| `GRADLE_USER_HOME`| Dossier du cache Gradle. | `/home/runner/.gradle` |

---

## 🏢 Recettes Prêtes à l'Emploi par Plateforme

### 1. GitLab Runner (`.gitlab-ci.yml`) - Spécial Réseau d'Entreprise
Ce modèle configure la mise en cache optimale des dépendances Gradle, la connexion à votre miroir Nexus et l'injection du proxy d'entreprise :

```yaml
image: hateum/android-ci-box:latest

stages:
  - test
  - build
  - deploy

variables:
  # Cache Gradle stocké dans le workspace du runner GitLab
  GRADLE_USER_HOME: "$CI_PROJECT_DIR/.gradle"
  
  # Détection automatique Nexus (URL de base ou groupe)
  NEXUS_URL: "https://nexus.entreprise.corp"
  NEXUS_USER: "gitlab-runner-sa"
  NEXUS_PASSWORD: "$NEXUS_PASSWORD_SECRET"
  
  # Proxy d'entreprise (optionnel)
  HTTPS_PROXY: "http://proxy.entreprise.corp:8080"
  HTTP_PROXY: "http://proxy.entreprise.corp:8080"
  NO_PROXY: "localhost,127.0.0.1,.entreprise.corp"

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - .gradle/caches/
    - .gradle/wrapper/

before_script:
  - chmod +x ./gradlew

# Étape 1 : Diagnostic rapide
diagnostics:
  stage: test
  script:
    - ci-doctor

# Étape 2 : Tests unitaires
unit_tests:
  stage: test
  script:
    - ./gradlew test

# Étape 3 : Compilation Release
build_release:
  stage: build
  script:
    - ./gradlew assembleRelease bundleRelease
  artifacts:
    expire_in: 7 days
    paths:
      - app/build/outputs/apk/release/*.apk
      - app/build/outputs/bundle/release/*.aab

# Étape 4 : Déploiement Fastlane (optionnel)
deploy_internal:
  stage: deploy
  script:
    - bundle exec fastlane internal_deploy
  only:
    - main
```

---

### 2. GitHub Actions (`.github/workflows/android-ci.yml`)
Pour vos projets open source ou exécutés sur des runners GitHub Actions hébergés :

```yaml
name: Android CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: hateum/android-ci-box:latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Cache Gradle Packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Diagnostics & Tests
        run: |
          ci-doctor
          ./gradlew test

      - name: Build APK & App Bundle
        run: ./gradlew assembleRelease bundleRelease

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: app/build/outputs/apk/release/*.apk
```

---

### 3. Jenkins (Pipeline Déclaratif `Jenkinsfile`)
```groovy
pipeline {
    agent {
        docker {
            image 'hateum/android-ci-box:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    environment {
        NEXUS_URL = 'https://nexus.entreprise.corp'
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
    }
    stages {
        stage('Diagnostic') {
            steps {
                sh 'ci-doctor'
            }
        }
        stage('Test & Build') {
            steps {
                sh './gradlew test assembleRelease'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'app/build/outputs/apk/release/*.apk', fingerprint: true
        }
    }
}
```

---

## 🛠️ Guide Pratique des Outils et Utilitaires Intégrés

### 1. `ci-doctor` : Vérification instantanée
Exécutez `ci-doctor` dans votre conteneur pour obtenir un diagnostic complet en 1 seconde :
```bash
ci-doctor
```
Il vérifie :
- 👤 L'utilisateur et son mode de sécurité (Root vs Non-Root).
- ☕ Le JDK actif (17 / 21) et la variable `JAVA_HOME`.
- 📱 Les SDKs Android installés (API 35, 36, 37) et les build-tools associés.
- 🚀 Les versions de Gradle, Fastlane, Bundletool, Python 3 et GitHub CLI.
- 🌐 L'état réseau (Proxy, nombre de certificats CA montés, miroir Nexus).
- 📡 Un test de ping HTTP réel vers `dl.google.com`, `repo.maven.apache.org` et votre serveur Nexus.

### 2. `switch-jdk` : Basculer entre Java 17 et Java 21
L'image est configurée par défaut avec **Java 21**. Si un de vos projets ou un plugin requiert **Java 17** :
```bash
# Basculer vers Java 17
switch-jdk 17

# Revenir vers Java 21
switch-jdk 21
```

### 3. `install-sdk-version` : Installer une version de SDK à chaud
Pour installer une version de plateforme spécifique ou un package preview :
```bash
# Installer la plateforme Android 37 et ses build-tools
install-sdk-version 37

# Installer un package SDK spécifique
install-sdk-version "build-tools;37.0.0"
```

### 4. `bundletool` : Manipulation des Android App Bundles (AAB)
L'exécutable `bundletool` est directement accessible dans le `PATH` :
```bash
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal
```

### 5. `gradle` Standalone
Vous pouvez exécuter directement des commandes Gradle sans dépendre du wrapper du projet :
```bash
gradle --version
gradle init
```

---

## 🧪 Suite de Qualité, Linters & Tests Automatisés

Le dépôt applique une stratégie d'assurance qualité à 3 niveaux avant toute mise en production :

### 1. Linters et Analyse Statique Continue (Pré-build)
- **Hadolint** : Validation stricte des bonnes pratiques Dockerfile, ordonnancement des calques et sécurité.
- **ShellCheck** : Analyse statique et détection de bugs ou failles d'injection sur tous les scripts Shell (`entrypoint.sh`, `ci-doctor`, `bin/switch-jdk`, `bin/install-sdk-version`, `tests/test-image.sh`).
- **Actionlint** : Vérification syntaxique et sémantique des workflows GitHub Actions (`.github/workflows/*.yml`).
- **Android Lint** : Analyse approfondie de code Android (`lintRelease`) et vérification d'AAR/Manifest sur le projet d'intégration.

### 2. Suite de Tests Fonctionnels Conteneurisés (`tests/test-image.sh`)
L'image exécute une suite de **7 tests d'intégration automatisés** :
1. **`ci-doctor`** : Validation globale de l'environnement, des variables et de la connectivité.
2. **Dual-JDK Switching** : Test de bascule bidirectionnelle entre Java 17 et Java 21 (`switch-jdk`).
3. **Android SDK Integrity** : Présence certifiée des API 35, 36, 37.0 (et symlink `android-37`) ainsi que des build-tools `35.0.0`, `36.0.0`, `37.0.0`.
4. **Tooling Verification** : Disponibilité et bon fonctionnement de `gradle 9.8.2`, `bundletool 1.18.3`, `fastlane`, `python3`, `pip`, `gh`.
5. **Simulation Réseau Entreprise** : Test d'injection d'un proxy corporate, de miroirs Nexus/Artifactory et d'un certificat d'autorité CA dans `gradle.properties` et le keystore `cacerts`.
6. **Compilation et Linters Réels Android** : Compilation complète du `SampleProject` sous **AGP 9.4.1**, **Gradle 9.8.2**, **Kotlin 2.4.20**, **compileSdk 37 / targetSdk 37**, avec exécution des tests unitaires (`./gradlew test lintRelease check assembleRelease`).
7. **Pipeline Fastlane** : Exécution de la lane `fastlane test`.

Pour exécuter la suite de tests en local :
```bash
docker run --rm \
  -v "$(pwd)":/project \
  -w /project \
  hateum/android-ci-box:latest \
  /project/tests/test-image.sh
```

---

## 🚢 Publication Automatisée sur Docker Hub & Multi-Tagging

Le pipeline GitHub Actions ([`.github/workflows/docker-publish.yml`](.github/workflows/docker-publish.yml)) orchestre la qualité, la sécurité et la publication multi-architecture :

1. **Job `lint`** :
   - Exécution simultanée de Hadolint, ShellCheck et Actionlint.
2. **Job `test`** :
   - Cache de build GitHub Actions (`cache-from: type=gha`, `cache-to: type=gha,mode=max`) accélérant les constructions d'image à 2 minutes.
   - Scan de Sécurité Automatisé **Trivy** (`aquasecurity/trivy-action`) avec rapport SARIF dans l'onglet **Security** de GitHub et règle bloquante `zero-unfixed-critical`.
   - Exécution de la suite de 7 tests en mode Root.
   - Test de sécurité sous utilisateur non-root durci (`--user 1000:0`).
   - Test de sécurité sous UID arbitraire strict (`--user 1001:1001`).
3. **Job `publish` (Multi-Arch & Multi-Tag)** :
   - Construction multi-architecture native `linux/amd64` et `linux/arm64` via QEMU et Docker Buildx.
   - Publication automatique sur Docker Hub :
     - `latest` : Image de référence par défaut.
     - `1.0.0` : Numéro de version sémantique exact (piloté par le fichier `VERSION`).
     - `1.0` : Alias de version mineure (mis à jour automatiquement).
     - `1` : Alias de version majeure (mis à jour automatiquement).
     - `sha-xxxxxxx` : Hash court du commit Git pour une traçabilité immuable.

---

## ⚡ Architecture de Performance 360°

L'image applique un ensemble d'optimisations coordonnées pour maximiser le débit des builds CI :

| Axe d'Optimisation | Mécanisme Implémenté | Bénéfice CI / Développeur |
| :--- | :--- | :--- |
| **Moteur JVM & GC** | OpenJDK 21 + Garbage Collector `G1GC` + `-XX:+ParallelRefProcEnabled` + JIT C2 complet | Réduction des temps de pause GC et compilation Kotlin / R8 jusqu'à **2x plus rapide**. |
| **Ordonnancement Gradle** | `org.gradle.parallel=true`, `org.gradle.caching=true`, `org.gradle.vfs.watch=false` | Parallélisation maximale des tâches sur les CPUs du runner et réutilisation des outputs. |
| **Slimming de l'Image** | Purge des documentations (`/usr/share/doc`, `/usr/share/man`), caches APT et gems | Temps de `docker pull` minimal sur les runners Kubernetes et GitLab. |
| **Stabilité & Anti-SIGPIPE** | Licences Android pré-calculées et injection POSIX sans blocage de pipe | Élimination des erreurs `exit code 141` sur shells stricts avec `pipefail`. |
| **Cache de Build Distant** | Support natif de `GRADLE_BUILD_CACHE_URL` dans `init.d` | Partage instantané des artefacts de compilation entre tous les jobs de l'entreprise. |

---

## 📱 Tests d'Instrumentation Automatisés : Gradle Managed Devices (GMD)

L'image `hateum/android-ci-box` supporte nativement **Gradle Managed Devices (GMD)** introduit par Google dans l'Android Gradle Plugin.

### 🌟 Avantages de l'approche intégrée
1. **Zéro intervention manuelle** : Plus besoin de scripts complexes de boot d'émulateur (`adb wait-for-device`, sleep, kill). AGP provisionne, démarre en headless, exécute les tests Espresso/UI Automator, génère les rapports et éteint automatiquement l'émulateur.
2. **Accélération graphique headless pré-configurée** : L'entrypoint injecte d'office `android.testoptions.manageddevices.emulator.gpu=swiftshader_indirect` dans `gradle.properties`, éliminant les crashs d'affichage sur les runners CI sans GPU physique.
3. **Limitation de concurrence CI** : `maxconcurrentdevices=1` est configuré pour protéger les runners contre les Out-Of-Memory (OOM).
4. **Support Matériel KVM & Tolérance** : Si `/dev/kvm` est monté, l'accélération matérielle est exploitée ; s'il est absent, le fallback logiciel fonctionne automatiquement.

---

### 🛠️ Configuration dans votre projet Android (`app/build.gradle` ou `build.gradle.kts`)

Déclarez simplement vos profils d'émulateurs standards et pliables :

```groovy
android {
    testOptions {
        animationsDisabled = true // Désactive les animations pour accélérer les tests
        managedDevices {
            allDevices {
                // Smartphone standard ultra-rapide (image Google ATD)
                pixel8api35(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "Pixel 8"
                    apiLevel = 35
                    systemImageSource = "google-atd"
                }
                // Écran pliable (Foldable 7.6 pouces)
                foldableApi36(com.android.build.api.dsl.ManagedVirtualDevice) {
                    device = "7.6in Foldable"
                    apiLevel = 36
                    systemImageSource = "google"
                }
            }
            groups {
                allFormFactors {
                    targetDevices.add(allDevices.pixel8api35)
                    targetDevices.add(allDevices.foldableApi36)
                }
            }
        }
    }
}
```

---

### 🚀 Exécution des Tests d'Instrumentation en CI

Lancez directement les tâches générées automatiquement par Gradle :

```bash
# Tester sur le smartphone standard Pixel 8 (Android 15)
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew pixel8api35DebugAndroidTest

# Tester sur l'écran pliable Foldable (Android 16)
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew foldableApi36DebugAndroidTest

# Tester simultanément sur l'ensemble du groupe de terminaux
docker run --rm --device /dev/kvm -v "$(pwd)":/project -w /project hateum/android-ci-box:latest \
  ./gradlew allFormFactorsGroupDebugAndroidTest
```

---

### 💾 Mise en Cache Recommandée en CI (GitHub Actions)

Pour éviter de retélécharger l'image système Android à chaque exécution du job CI, mettez en cache les répertoires d'AVD et d'images système :

```yaml
- name: Cache Android Emulators & System Images
  uses: actions/cache@v4
  with:
    path: |
      /opt/android-sdk/system-images
      /home/runner/.android/avd
    key: ${{ runner.os }}-android-emulator-${{ hashFiles('**/build.gradle*') }}
    restore-keys: |
      ${{ runner.os }}-android-emulator-
```

---

## ❓ FAQ & Dépannage Rapide

### 1. Comment résoudre l'erreur SSL `PKIX path building failed` ?
Cette erreur se produit quand le réseau d'entreprise effectue une inspection SSL (déchiffrement des flux HTTPS via un boîtier Zscaler, Netskope, etc.).
👉 **Solution** : Montez le certificat de votre entreprise dans `/certificates` :
```bash
docker run -v /mon/certificat-entreprise.crt:/certificates/corp.crt ...
```
L'image l'importera automatiquement dans le trousseau de certificats Linux ET dans le truststore Java `cacerts`.

### 2. Comment utiliser l'image sur OpenShift ou un runner non-root ?
L'image a été conçue pour supporter nativement les utilisateurs avec UID arbitraire (standard OpenShift et Kubernetes) :
```bash
docker run --user 1000:0 ...
```
Tous les répertoires de travail (`/project`, `/builds`, `/home/runner/.gradle`, `/certificates`) disposent des permissions d'écriture nécessaires pour éviter toute erreur `Permission Denied`.

### 3. Comment désactiver le daemon Gradle pour libérer la RAM ?
Le conteneur intègre déjà `org.gradle.daemon=false` d'office pour éviter que des processus fantômes restent en mémoire sur vos serveurs de build.

---

## 📄 Licence
Ce projet est distribué sous licence [MIT](LICENSE).
