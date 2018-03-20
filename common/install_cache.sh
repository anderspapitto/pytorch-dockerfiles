#!/bin/bash

set -ex

# Setup compiler cache
if [ -n "$CUDA_VERSION" ]; then
  # If CUDA is installed, we must use ccache, as sccache doesn't support
  # caching nvcc yet

  # Install ccache from source.
  # Needs 3.4 or later for ccbin support
  pushd /tmp
  git clone https://github.com/ccache/ccache -b v3.4.1
  pushd ccache
  # Disable developer mode, so we squelch -Werror
  ./autogen.sh
  ./configure --prefix=/usr/local
  make "-j$(nproc)" install
  popd
  popd

  # Install ccache symlink wrappers
  pushd /usr/local/bin
  ln -sf "$(which ccache)" cc
  ln -sf "$(which ccache)" c++
  ln -sf "$(which ccache)" gcc
  ln -sf "$(which ccache)" g++
  ln -sf "$(which ccache)" clang
  ln -sf "$(which ccache)" clang++
  ln -sf "$(which ccache)" nvcc
  popd

else
  # We prefer sccache because we don't have to have a warm local ccache
  # to use it

  pushd /tmp
  SCCACHE_BASE_URL="https://github.com/mozilla/sccache/releases/download/"
  SCCACHE_VERSION="0.2.5"
  SCCACHE_BASE="sccache-${SCCACHE_VERSION}-x86_64-unknown-linux-musl"
  SCCACHE_FILE="$SCCACHE_BASE.tar.gz"
  wget -q "$SCCACHE_BASE_URL/$SCCACHE_VERSION/$SCCACHE_FILE"
  tar xzf $SCCACHE_FILE
  mv "$SCCACHE_BASE/sccache" /usr/local/bin
  popd

  function write_sccache_stub() {
    printf "#!/bin/sh\nexec sccache /usr/bin/$1 \$*" > "/usr/local/bin/$1"
    chmod a+x "/usr/local/bin/$1"
  }

  write_sccache_stub cc
  write_sccache_stub c++
  write_sccache_stub gcc
  write_sccache_stub g++
  write_sccache_stub clang
  write_sccache_stub clang++
  write_sccache_stub nvcc

fi