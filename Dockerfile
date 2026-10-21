# ==============================================================================
# Docker Android CI Build Box
# Optimized, Multi-arch (amd64 / arm64), Universal (Internet & Enterprise Ready)
# Includes: Gradle 9.8.2 (Standalone & Wrapper ready), Android SDK (API 35, 36, 37),
#           Build-tools 35, 36, 37, OpenJDK 17 & 21 (Headless), Fastlane, Ruby,
#           Python3, Bundletool (1.18.3), GitHub CLI (gh), ci-doctor CLI,
#           Hardened Root & Non-Root Support
# ==============================================================================

FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build Arguments with verified latest versions
ARG ANDROID_SDK_TOOLS_VERSION="15859902"
ARG BUNDLETOOL_VERSION="1.18.3"
ARG GRADLE_VERSION="9.8.2"
ARG DEBIAN_FRONTEND="noninteractive"

# Standard Environment Variables
ENV ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    BUNDLETOOL_PATH="/opt/bundletool/bundletool.jar" \
    GRADLE_HOME="/opt/gradle/gradle-${GRADLE_VERSION}" \
    GRADLE_USER_HOME="/home/runner/.gradle" \
    HOME="/home/runner" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TZ="UTC"

# Layer 1: Base system dependencies, Python3, Ruby & OpenJDK (headless)
RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        git-lfs \
        gnupg \
        locales \
        openjdk-17-jdk-headless \
        openjdk-21-jdk-headless \
        openssh-client \
        pkg-config \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        ruby-full \
        ruby-dev \
        tzdata \
        unzip \
        wget \
        zip \
        zlib1g-dev && \
    locale-gen "${LANG}" && \
    update-locale LANG="${LANG}" LC_ALL="${LC_ALL}" && \
    touch /etc/subuid /etc/subgid && \
    (userdel -r ubuntu 2>/dev/null || true) && \
    (id -u runner >/dev/null 2>&1 || useradd -u 1000 -g 0 -m -s /bin/bash runner) && \
    mkdir -p /home/runner/.gradle /root && \
    ln -sf /home/runner/.gradle /root/.gradle && \
    mkdir -p /etc && \
    printf "[global]\nbreak-system-packages = true\n" > /etc/pip.conf && \
    ARCH=$(dpkg --print-architecture) && \
    ln -s "/usr/lib/jvm/java-21-openjdk-${ARCH}" /opt/jdk-21 && \
    ln -s "/usr/lib/jvm/java-17-openjdk-${ARCH}" /opt/jdk-17 && \
    ln -s /opt/jdk-21 /opt/default-jdk && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Layer 2: Install GitHub CLI (gh)
RUN mkdir -p /etc/apt/keyrings && \
    chmod 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends gh && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Layer 3: Fastlane and Bundler
RUN gem install bundler fastlane --no-document && \
    rm -rf /root/.gem /root/.bundle /home/runner/.gem /home/runner/.bundle

# Layer 4: Install Latest Stable Gradle (9.8.2) Standalone
RUN mkdir -p /opt/gradle && \
    curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt/gradle && \
    ln -s "/opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle && \
    rm -f /tmp/gradle.zip

# Configure default JAVA_HOME and PATH (including Gradle and Android tools)
ENV JAVA_HOME="/opt/default-jdk"
ENV PATH="${GRADLE_HOME}/bin:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Layer 5: Helper scripts
COPY bin/switch-jdk /usr/local/bin/switch-jdk
COPY bin/install-sdk-version /usr/local/bin/install-sdk-version
RUN chmod +x /usr/local/bin/switch-jdk /usr/local/bin/install-sdk-version

# Layer 6: Install Android Command-Line Tools & SDK components (API 35, 36, 37.0 + build-tools)
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" && \
    mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" && \
    rm -f /tmp/cmdline-tools.zip && \
    yes | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" --licenses && \
    yes | "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" \
        "platform-tools" \
        "platforms;android-35" \
        "platforms;android-36" \
        "platforms;android-37.0" \
        "build-tools;35.0.0" \
        "build-tools;36.0.0" \
        "build-tools;37.0.0" && \
    ln -snf "${ANDROID_HOME}/platforms/android-37.0" "${ANDROID_HOME}/platforms/android-37" && \
    mkdir -p /opt/bundletool && \
    curl -fsSL "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" -o "${BUNDLETOOL_PATH}" && \
    printf '#!/bin/sh\nexec java -jar /opt/bundletool/bundletool.jar "$@"\n' > /usr/local/bin/bundletool && \
    chmod +x /usr/local/bin/bundletool && \
    mkdir -p /builds /project /certificates && \
    chmod -R 777 "${ANDROID_HOME}" /opt/gradle /home/runner /builds /project /certificates && \
    find /opt -name "cacerts" -exec chmod 666 {} + 2>/dev/null || true && \
    chmod -R 777 /usr/local/share/ca-certificates 2>/dev/null || true

# Copy and install utilities
COPY ci-doctor /usr/local/bin/ci-doctor
RUN chmod +x /usr/local/bin/ci-doctor

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Working directory
WORKDIR /project

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD ["ci-doctor", "--summary"]

# OCI Standard Image Metadata Labels
LABEL org.opencontainers.image.title="hateum/android-ci-box" \
      org.opencontainers.image.description="Fast, optimized, multi-arch Android CI/CD build box with Gradle 9.8.2, Android SDK 35/36/37, OpenJDK 17/21, Fastlane, Python3, Bundletool & Universal Network Auto-Detection" \
      org.opencontainers.image.authors="Hatem Noureddine" \
      org.opencontainers.image.vendor="hateum" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/hatem-noureddine/android-ci" \
      org.opencontainers.image.documentation="https://github.com/hatem-noureddine/android-ci#readme"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
