#!/bin/bash
# Copyright (C) 2026 EclipseSource GmbH and others.
#
# This program and the accompanying materials are made available under the
# terms of the MIT License, which is available in the project root.
#
# SPDX-License-Identifier: MIT

# Install a pinned Gradle distribution in the user tool prefix. Bump
# GRADLE_VERSION and GRADLE_SHA256 together.
set -euo pipefail

GRADLE_VERSION=9.8.2
GRADLE_SHA256=21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607
GRADLE_URL="https://github.com/gradle/gradle-distributions/releases/download/v${GRADLE_VERSION}/gradle-${GRADLE_VERSION}-bin.zip"

# spec.yaml sets JAVA_HOME to this path, and gradle refuses to start when
# JAVA_HOME is invalid.
java_home=/usr/lib/jvm/default-java
if [ ! -x "$java_home/bin/javac" ]; then
    echo "$java_home/bin/javac not found, JAVA_HOME would be invalid" >&2
    exit 1
fi

gradle_root="$HOME/.local/share/gradle"
download_dir="$(mktemp -d)"
trap 'rm -rf "$download_dir"' EXIT

archive="$download_dir/gradle-${GRADLE_VERSION}-bin.zip"
curl -fsSL --retry 3 -o "$archive" "$GRADLE_URL"
echo "${GRADLE_SHA256}  ${archive}" | sha256sum -c --quiet -

mkdir -p "$gradle_root" "$HOME/.local/bin"
unzip -q "$archive" -d "$gradle_root"
ln -sfn "$gradle_root/gradle-${GRADLE_VERSION}/bin/gradle" "$HOME/.local/bin/gradle"

# The cache mounts land inside ~/.gradle. Create it here so the agent owns it
# and can write siblings such as gradle.properties.
mkdir -p "$HOME/.gradle"

echo "Gradle ${GRADLE_VERSION} installed"
