#!/bin/bash

set -euo pipefail

target=$1

if [ -z "$target" ]; then
  echo "You must specify a target (wasm32-wasi or wasm32-emscripten)"
  exit 1
fi

CONFIGURE="./configure"
MAKE="make"

if [ "$target" == "wasm32-emscripten" ]; then
  CONFIGURE="emconfigure $CONFIGURE"
  MAKE="emmake $MAKE"
elif [ "$target" == "wasm32-wasi" ]; then
  export CC="$WASI_SDK_PATH/bin/clang --sysroot=$WASI_SDK_PATH/share/wasi-sysroot"
  export AR="$WASI_SDK_PATH/bin/llvm-ar"
  export RANLIB="$WASI_SDK_PATH/bin/llvm-ranlib"
  export LD="$WASI_SDK_PATH/bin/wasm-ld"
  export CFLAGS="-DEVENT__HAVE_SIGNAL=0 -DEVENT__HAVE_SIGACTION=0 -D__wasi__=1"
fi

if [ ! -f "./configure" ]; then
  ./autogen.sh
fi

$CONFIGURE --host wasm32 \
  --disable-dependency-tracking \
  --disable-shared \
  --disable-thread-support \
  --disable-openssl \
  --disable-malloc-replacement \
  --disable-samples

$MAKE

mkdir -p "targets/$target"
cp .libs/*.a "targets/$target/"

echo "Finished compiling libevent for $target. Output in targets/$target"
