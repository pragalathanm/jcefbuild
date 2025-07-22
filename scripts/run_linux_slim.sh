#!/usr/bin/env bash
set -euo pipefail

TARGETARCH=${1:-amd64}
BUILD_TYPE=${2:-Release}

echo "🔧 Building JCEF for ${TARGETARCH} (${BUILD_TYPE})"

# Clone JCEF if missing
if [ ! -d "/jcef" ]; then
  echo "📦 Cloning JCEF repo..."
  git clone https://bitbucket.org/chromiumembedded/jcef.git /jcef
  cd /jcef
  git checkout master
else
  echo "📁 Found existing JCEF source"
  cd /jcef
fi

# Patch CMakeLists.txt to disable unused features
echo "🧹 Patching CMakeLists.txt..."
sed -i 's/ENABLE_PDF_SUPPORT ON/ENABLE_PDF_SUPPORT OFF/' CMakeLists.txt || true
sed -i 's/ENABLE_PLUGIN_SUPPORT ON/ENABLE_PLUGIN_SUPPORT OFF/' CMakeLists.txt || true
sed -i 's/ENABLE_PRINTING_SUPPORT ON/ENABLE_PRINTING_SUPPORT OFF/' CMakeLists.txt || true

# Create build directory
mkdir -p jcef_build
cd jcef_build

# Configure CMake with Ninja
cmake -G "Ninja" \
  -DPROJECT_ARCH=${TARGETARCH} \
  -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
  -DENABLE_AUDIO=ON \
  -DENABLE_VIDEO=OFF \
  -DENABLE_PDF_SUPPORT=OFF \
  -DENABLE_PLUGIN_SUPPORT=OFF \
  -DENABLE_PRINTING_SUPPORT=OFF \
  ..

# Build native binaries
ninja -j$(nproc)

# Compile Java classes
cd ../tools
chmod +x compile.sh
./compile.sh linux64

# Generate distribution
cd ..
chmod +x make_distrib.sh
./make_distrib.sh linux64

# Trim locales to English only
echo "🧹 Removing unused locales..."
rm -rf binary_distrib/linux64/bin/locales/*
cp jcef/cef_binary/locales/en-US.pak binary_distrib/linux64/bin/locales/

# Strip libcef if Release build
if [ "${BUILD_TYPE}" == "Release" ]; then
  echo "🔪 Stripping libcef.so..."
  strip binary_distrib/linux64/bin/lib/linux64/libcef.so || true
fi

# Prepare artifacts for CI
if [ "${CI:-}" = "true" ]; then
  echo "📦 Preparing artifacts for upload..."
  mkdir -p /jcef/artifacts
  cp binary_distrib/linux64/bin/lib/linux64/libcef.so /jcef/artifacts/
  cp binary_distrib/linux64/bin/lib/linux64/libjcef.so /jcef/artifacts/
  cp binary_distrib/linux64/bin/jcef.jar /jcef/artifacts/
  cp binary_distrib/linux64/bin/locales/en-US.pak /jcef/artifacts/
fi

echo "✅ Slim JCEF build complete."
