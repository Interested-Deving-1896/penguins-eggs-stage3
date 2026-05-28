#!/usr/bin/env bash
# distros/opensuse.sh — openSUSE bootstrap via zypper --root

OPENSUSE_MIRROR="${OPENSUSE_MIRROR:-https://download.opensuse.org}"

# Map Debian arch names to openSUSE arch names
declare -A ARCH_MAP=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armv7hl
  [ppc64el]=ppc64le [s390x]=s390x [i386]=i586
)
SUSE_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"

# Normalize release: "tumbleweed" or "15.6" etc.
case "$RELEASE" in
  tumbleweed|tw) REPO_PATH="tumbleweed/repo/oss" ;;
  *)             REPO_PATH="distribution/leap/${RELEASE}/repo/oss" ;;
esac
REPO_URL="${OPENSUSE_MIRROR}/${REPO_PATH}"

do_bootstrap() {
  info "Bootstrapping openSUSE ${RELEASE}/${ARCH} via zypper --root"

  if ! command -v zypper &>/dev/null; then
    apt-get install -y --no-install-recommends zypper 2>/dev/null || \
      die "zypper not available — install it or run on an openSUSE host"
  fi

  mkdir -p "${ROOTFS}/etc/zypp"

  zypper \
    --root "${ROOTFS}" \
    --non-interactive \
    addrepo --no-gpgcheck \
    "${REPO_URL}" \
    "oss"

  zypper \
    --root "${ROOTFS}" \
    --non-interactive \
    install -y \
    --no-recommends \
    patterns-base-base \
    bash \
    coreutils \
    glibc
}

install_stage3_packages() {
  zypper --non-interactive install -y --no-recommends \
    gcc gcc-c++ binutils make cmake ninja \
    autoconf automake libtool pkg-config \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    go \
    git curl wget \
    ca-certificates \
    sudo \
    util-linux \
    xz zstd \
    dosfstools \
    kernel-headers
  zypper clean --all
}
