# ==============================================================================
# Docker Android CI Build Box
# Optimized, Multi-arch (amd64 / arm64), Universal (Internet & Enterprise Ready)
# Includes: Gradle 9.8.2 (Standalone & Wrapper ready), Android SDK (API 35, 36, 37),
#           Build-tools 35, 36, 37, OpenJDK 17 & 21 (Headless), Fastlane 2.241.2,
#           Ruby 4.0.9 (rbenv), Python3, Bundletool (1.18.3), GitHub CLI (gh),
#           ci-doctor CLI, Hardened Root & Non-Root Support
# ==============================================================================

FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build Arguments with verified latest versions
ARG ANDROID_SDK_TOOLS_VERSION="15859902"
ARG BUNDLETOOL_VERSION="1.18.3"
ARG GRADLE_VERSION="9.8.2"
ARG RUBY_VERSION="4.0.9"
ARG FASTLANE_VERSION="2.241.2"
ARG BUNDLER_VERSION="4.0.23"
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
    RBENV_ROOT="/opt/rbenv" \
    TZ="UTC"

# Layer 1: Base system dependencies, Python3 & OpenJDK (headless)
RUN apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
        apt-transport-https \
        autoconf \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        git-lfs \
        gnupg \
        libasound2t64 \
        libegl1 \
        libffi-dev \
        libgl1 \
        libglu1-mesa \
        libgmp-dev \
        libnss3 \
        libpng16-16t64 \
        libpulse0 \
        libreadline-dev \
        libssl-dev \
        libvulkan1 \
        libxcomposite1 \
        libxcursor1 \
        libxi6 \
        libxkbfile1 \
        libxrandr2 \
        libxtst6 \
        libyaml-dev \
        locales \
        openjdk-17-jdk-headless \
        openjdk-21-jdk-headless \
        openssh-client \
        pkg-config \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        tzdata \
        unzip \
        wget \
        zip \
        zlib1g-dev && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        sed -i 's/^Types: deb$/Types: deb\nArchitectures: arm64/' /etc/apt/sources.list.d/ubuntu.sources && \
        printf "Types: deb\nURIs: http://archive.ubuntu.com/ubuntu/\nSuites: noble noble-updates noble-backports\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nArchitectures: amd64\n\nTypes: deb\nURIs: http://security.ubuntu.com/ubuntu/\nSuites: noble-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nArchitectures: amd64\n" > /etc/apt/sources.list.d/amd64.sources && \
        dpkg --add-architecture amd64 && \
        apt-get update -qq && \
        apt-get install -qq -y --no-install-recommends libc6:amd64 libstdc++6:amd64 zlib1g:amd64; \
    fi && \
    locale-gen "${LANG}" && \
    update-locale LANG="${LANG}" LC_ALL="${LC_ALL}" && \
    touch /etc/subuid /etc/subgid && \
    (userdel -r ubuntu 2>/dev/null || true) && \
    (id -u runner >/dev/null 2>&1 || useradd -u 1000 -g 0 -m -s /bin/bash runner) && \
    mkdir -p /home/runner/.gradle /root && \
    ln -sf /home/runner/.gradle /root/.gradle && \
    mkdir -p /etc && \
    printf "[global]\nbreak-system-packages = true\n" > /etc/pip.conf && \
    ln -s "/usr/lib/jvm/java-21-openjdk-${ARCH}" /opt/jdk-21 && \
    ln -s "/usr/lib/jvm/java-17-openjdk-${ARCH}" /opt/jdk-17 && \
    ln -s /opt/jdk-21 /opt/default-jdk && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man /usr/share/doc /usr/share/info

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

# Layer 3: Ruby 4.0 (rbenv + ruby-build) & Fastlane (Fast parallel native compilation)
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git "${RBENV_ROOT}" && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build" && \
    chmod -R 755 "${RBENV_ROOT}" && \
    MAKE_OPTS="-j$(nproc)" RUBY_CONFIGURE_OPTS="--disable-install-doc --disable-yjit" "${RBENV_ROOT}/bin/rbenv" install "${RUBY_VERSION}" && \
    "${RBENV_ROOT}/bin/rbenv" global "${RUBY_VERSION}" && \
    "${RBENV_ROOT}/shims/gem" install "bundler:${BUNDLER_VERSION}" "fastlane:${FASTLANE_VERSION}" json --no-document && \
    "${RBENV_ROOT}/bin/rbenv" rehash && \
    chmod -R 777 "${RBENV_ROOT}" && \
    rm -rf /root/.gem /root/.bundle /home/runner/.gem /home/runner/.bundle /tmp/* /var/tmp/*

# Layer 4: Install Latest Stable Gradle (9.8.2) Standalone & Global CI Optimizations
RUN mkdir -p /opt/gradle /opt/gradle/init.d && \
    curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt/gradle && \
    ln -s "/opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle && \
    printf "allprojects {\n    tasks.withType(JavaCompile).configureEach {\n        options.fork = true\n        options.encoding = 'UTF-8'\n    }\n}\ngradle.projectsLoaded {\n    rootProject.logger.info('⚡ [hateum/android-ci-box] CI Optimizations active: parallel=true, buildCache=true, daemon=false')\n}\n" > /opt/gradle/init.d/ci-optimizations.gradle && \
    rm -f /tmp/gradle.zip

# Configure default JAVA_HOME, ANDROID_AVD_HOME and PATH (including Gradle and Android tools)
ENV JAVA_HOME="/opt/default-jdk"
ENV ANDROID_AVD_HOME="/home/runner/.android/avd"
ENV PATH="${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${GRADLE_HOME}/bin:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"

# Layer 5: Helper scripts
COPY bin/switch-jdk /usr/local/bin/switch-jdk
COPY bin/install-sdk-version /usr/local/bin/install-sdk-version
COPY bin/install-ndk-version /usr/local/bin/install-ndk-version
COPY bin/detect-android-project /usr/local/bin/detect-android-project
RUN chmod +x /usr/local/bin/switch-jdk /usr/local/bin/install-sdk-version /usr/local/bin/install-ndk-version /usr/local/bin/detect-android-project

# Layer 6: Install Android Command-Line Tools & SDK components (API 35, 36, 37.0 + emulator + build-tools)
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" "${ANDROID_HOME}/licenses" && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" && \
    mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" && \
    rm -f /tmp/cmdline-tools.zip && \
    printf "8937372298270f79dd511e7c739bc7a53929e002\n24333f8a63b6825ea9c5514f83c2829b004d1fee\nd56f5187479451eabf01fb78af6dfcb131a6481e\n" > "${ANDROID_HOME}/licenses/android-sdk-license" && \
    printf "84831b9409646a918e30573bab4c9c91346d8abd\n" > "${ANDROID_HOME}/licenses/android-sdk-preview-license" && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" "emulator"; \
    fi && \
    "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" \
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
    mkdir -p /builds /project /certificates /usr/local/share/ca-certificates /home/runner/.gradle /home/runner/.android/avd "${ANDROID_HOME}/ndk" "${ANDROID_HOME}/cmake" && \
    chmod 1777 /opt 2>/dev/null || true && \
    chmod 777 /opt/default-jdk 2>/dev/null || true && \
    chmod -R 777 "${ANDROID_HOME}" /opt/gradle /home/runner /builds /project /certificates /usr/local/share/ca-certificates && \
    find /opt -name "cacerts" -exec chmod 666 {} +

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
ARG VERSION="1.0.0"
LABEL org.opencontainers.image.title="hateum/android-ci-box" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="Fast, optimized, multi-arch Android CI/CD build box with Gradle 9.8.2, Android SDK 35/36/37, OpenJDK 17/21, Ruby 4.0.9, Fastlane 2.241.2, Python3, Bundletool & Universal Network Auto-Detection" \
      org.opencontainers.image.authors="Hatem Noureddine" \
      org.opencontainers.image.vendor="hateum" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/hatem-noureddine/android-ci" \
      org.opencontainers.image.documentation="https://github.com/hatem-noureddine/android-ci#readme"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
