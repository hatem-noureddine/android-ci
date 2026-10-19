# ==============================================================================
# Docker Android CI Build Box
# Optimized, Multi-arch (amd64 / arm64), Fast & Lightweight CI/CD Image
# Includes: Android SDK (API 34 & 35), OpenJDK 17 & 21 (default 21), Fastlane,
#           Bundletool, GitHub CLI (gh), git, curl, zip
# ==============================================================================

FROM ubuntu:24.04

# Arguments for versions
ARG ANDROID_SDK_TOOLS_VERSION="13114758"
ARG BUNDLETOOL_VERSION="1.18.1"
ARG DEBIAN_FRONTEND="noninteractive"

# Standard Environment Variables
ENV ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    BUNDLETOOL_PATH="/opt/bundletool/bundletool.jar" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    TZ="UTC"

# Base system dependencies & OpenJDK (headless to minimize image size)
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
        ruby-full \
        ruby-dev \
        tzdata \
        unzip \
        wget \
        zip \
        zlib1g-dev && \
    locale-gen ${LANG} && \
    update-locale LANG=${LANG} LC_ALL=${LC_ALL} && \
    # Setup JDK symlinks for cross-platform convenience (amd64 & arm64)
    ARCH=$(dpkg --print-architecture) && \
    ln -s /usr/lib/jvm/java-21-openjdk-${ARCH} /opt/jdk-21 && \
    ln -s /usr/lib/jvm/java-17-openjdk-${ARCH} /opt/jdk-17 && \
    ln -s /opt/jdk-21 /opt/default-jdk && \
    # Install GitHub CLI (gh)
    mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends gh && \
    # Fastlane and Bundler (installed without docs to save space)
    gem install bundler fastlane --no-document && \
    # Clean apt and gem caches
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.gem /root/.bundle

# Configure default JAVA_HOME and PATH
ENV JAVA_HOME="/opt/default-jdk"
ENV PATH="${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Install Android Command-Line Tools & SDK components
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm -f /tmp/cmdline-tools.zip && \
    # Pre-accept all licenses
    yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1 && \
    # Install platform-tools, platforms and build-tools for API 34 & 35
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --install \
        "platform-tools" \
        "platforms;android-34" \
        "platforms;android-35" \
        "build-tools;34.0.0" \
        "build-tools;35.0.0" > /dev/null && \
    # Download Bundletool and create executable wrapper
    mkdir -p /opt/bundletool && \
    curl -fsSL "https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar" -o ${BUNDLETOOL_PATH} && \
    printf '#!/bin/sh\nexec java -jar /opt/bundletool/bundletool.jar "$@"\n' > /usr/local/bin/bundletool && \
    chmod +x /usr/local/bin/bundletool && \
    # Create helper script to switch JDK easily between 17 and 21
    printf '#!/bin/bash\nset -e\nARCH=$(dpkg --print-architecture)\ncase "$1" in\n  17)\n    export JAVA_HOME="/opt/jdk-17"\n    ln -snf /opt/jdk-17 /opt/default-jdk\n    echo "Switched to JDK 17 ($JAVA_HOME)"\n    ;;\n  21)\n    export JAVA_HOME="/opt/jdk-21"\n    ln -snf /opt/jdk-21 /opt/default-jdk\n    echo "Switched to JDK 21 ($JAVA_HOME)"\n    ;;\n  *)\n    echo "Usage: switch-jdk [17|21]"\n    exit 1\n    ;;\nesac\n' > /usr/local/bin/switch-jdk && \
    chmod +x /usr/local/bin/switch-jdk && \
    # Ensure wide permissions for non-root CI runners (Jenkins, GitLab CI, GitHub Actions)
    mkdir -p /project && \
    chmod -R 777 ${ANDROID_HOME} && \
    chmod 777 /project

# Working directory
WORKDIR /project

# OCI Standard Image Metadata Labels
LABEL org.opencontainers.image.title="hateum/android-ci-box" \
      org.opencontainers.image.description="Fast, optimized, multi-arch Android CI/CD build box with Android SDK 34/35, OpenJDK 17/21, Fastlane & Bundletool" \
      org.opencontainers.image.authors="Hatem Noureddine" \
      org.opencontainers.image.vendor="hateum" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/hateum/android-ci-box" \
      org.opencontainers.image.documentation="https://github.com/hateum/android-ci-box#readme"

CMD ["/bin/bash"]
