#!/usr/bin/env bash
# distros/ubuntu.sh — Ubuntu bootstrap

UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"
# For non-amd64/i386, use ports mirror
case "$ARCH" in
  amd64|i386) ;;
  *) UBUNTU_MIRROR="${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}" ;;
esac

do_bootstrap() {
  info "Bootstrapping Ubuntu ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${UBUNTU_MIRROR}"
}

install_stage3_packages() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    build-essential gcc g++ binutils make cmake ninja-build \
    autoconf automake libtool pkg-config \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    golang-go \
    git curl wget \
    ca-certificates \
    sudo \
    util-linux \
    xz-utils zstd \
    dosfstools
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
