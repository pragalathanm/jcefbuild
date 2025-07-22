#!/usr/bin/env bash
set -euo pipefail

ARCH=${1:-amd64}
BUILD_TYPE=${2:-Release}

# Clone CEF if not already present
if [ ! -d "cef" ]; then
  git clone https://bitbucket.org/chromiumembedded/cef.git
fi

cd cef

# Create GN args file
mkdir -p out/${BUILD_TYPE}
cat > out/${BUILD_TYPE}/args.gn <<EOF
is_clang = true
is_component_build = false
is_debug = false
symbol_level = 0
use_sysroot = false

# Audio-only support
enable_media = true
enable_platform_software_video_decoder = false
proprietary_codecs = false
use_opus = true

# Disable unused features
enable_plugins = false
enable_pdf = false
enable_print_preview = false
enable_spellcheck = false
enable_nacl = false
use_ozone = false
use_aura = false
enable_websockets = false
enable_webrtc = false
enable_extensions = false
enable_background_mode = false

# Performance
blink_symbol_level = 0
v8_symbol_level = 0
EOF

# Generate build files and compile
gn gen out/${BUILD_TYPE}
ninja -C out/${BUILD_TYPE} cefsimple libcef

# Optional: remove locales except en-US
rm -rf out/${BUILD_TYPE}/locales/*
cp /path/to/en-US.pak out/${BUILD_TYPE}/locales/

echo "✅ Slim CEF build complete."
