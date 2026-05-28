#!/usr/bin/env bash
# distros/devuan.sh — Devuan bootstrap (systemd-free Debian fork)

DEVUAN_MIRROR="${DEVUAN_MIRROR:-http://deb.devuan.org/merged}"

do_bootstrap() {
  info "Bootstrapping Devuan ${RELEASE}/${ARCH} via debootstrap"
  apt-get install -y --no-install-recommends debootstrap 2>/dev/null || true

  # Devuan uses its own keyring — fetch it first
  local keyring_deb
  keyring_deb=$(curl -sL "${DEVUAN_MIRROR}/pool/main/d/devuan-keyring/" \
    | grep -oP 'devuan-keyring_[^"]+\.deb' | tail -1)
  if [[ -n "$keyring_deb" ]]; then
    curl -sL "${DEVUAN_MIRROR}/pool/main/d/devuan-keyring/${keyring_deb}" \
      -o /tmp/devuan-keyring.deb
    dpkg -i /tmp/devuan-keyring.deb 2>/dev/null || true
    rm -f /tmp/devuan-keyring.deb
  fi

  debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=ca-certificates,devuan-keyring \
    --keyring=/usr/share/keyrings/devuan-archive-keyring.gpg \
    "${RELEASE}" \
    "${ROOTFS}" \
    "${DEVUAN_MIRROR}"
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
    sysvinit-core
  apt-get clean
  rm -rf /var/lib/apt/lists/*
}
