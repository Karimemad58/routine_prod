#!/usr/bin/env bash
set -euo pipefail

echo "Installing OS packages..."
apt-get update -y
apt-get install -y curl unzip xz-utils git

echo "Cloning Flutter SDK (stable)..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

echo "Ensuring web tooling..."
flutter precache --web || true

echo "Building Flutter web..."
flutter pub get
flutter build web --release

echo "Build finished. Output: build/web"
