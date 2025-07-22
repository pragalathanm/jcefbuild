#!/usr/bin/env bash
set -euo pipefail

# Architecture and build type
TARGETARCH=${1:-amd64}
BUILD_TYPE=${2:-Release}

echo "🔧 Building JCEF for ${TARGETARCH} (${BUILD_TYPE})"

# Clone JCEF if missing
if [ ! -d "jcef" ]; then
  git clone https://bitbucket.org/chromiumembedded/jcef.git
fi

cd jcef

# Patch CMakeLists.txt to skip unused features
sed -i 's/ENABLE_PDF_SUPPORT ON/ENABLE_PDF_SUPPORT OFF/' CMakeLists.txt
sed -i 's/ENABLE_PLUGIN_SUPPORT ON/ENABLE_PLUGIN_SUPPORT OFF/' CMakeLists.txt
sed -i 's/ENABLE_PRINTING_SUPPORT ON/ENABLE_PRINTING_SUPPORT OFF/' CMakeLists.txt

# Build native binaries
mkdir -p out/${BUILD_TYPE}
cd out/${BUILD_TYPE}

cmake ../.. \
  -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
  -DPROJECT_ARCH=${TARGETARCH} \
  -DCLANG=ON \
  -DENABLE_AUDIO=ON \
  -DENABLE_VIDEO=OFF \
  -DENABLE_PDF_SUPPORT=OFF \
  -DENABLE_PLUGIN_SUPPORT=OFF \
  -DENABLE_PRINTING_SUPPORT=OFF

ninja

# Strip unused locales
echo "🧹 Trimming locales..."
rm -rf cef_binary/locales/*
cp cef_binary/locales/en-US.pak cef_binary/locales/

# Upload minimal artifacts (if running in CI)
if [ "${CI:-}" = "true" ]; then
  echo "📦 Uploading artifacts..."
  mkdir -p ../../artifacts
  cp jcef.jar ../../artifacts/
  cp libjcef.so ../../artifacts/
  cp libcef.so ../../artifacts/
  cp cef_binary/locales/en-US.pak ../../artifacts/
fi

echo "✅ Slim JCEF build complete."
