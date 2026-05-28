#!/usr/bin/env bash
# distros/debian.sh — Debian bootstrap (also used by Ubuntu and Devuan via symlink)
# Variables available: DISTRO RELEASE ARCH ROOTFS JOBS

DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"

do_bootstrap() {
  info "Bootstrapping Debian ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${DEBIAN_MIRROR}"
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
    dosfstools \
    linux-headers-generic 2>/dev/null || \
  apt-get install -y --no-install-recommends \
    linux-headers-amd64 linux-headers-arm64 linux-headers-armmp \
    linux-headers-riscv64 2>/dev/null || true
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
