#!/usr/bin/env bash
# distros/fedora.sh — Fedora bootstrap via dnf --installroot

# Map Debian arch names to RPM arch names
declare -A ARCH_MAP=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armhfp
  [ppc64el]=ppc64le [s390x]=s390x [i386]=i686
)
RPM_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"

do_bootstrap() {
  info "Bootstrapping Fedora ${RELEASE}/${ARCH} via dnf --installroot"

  if ! command -v dnf &>/dev/null; then
    apt-get install -y --no-install-recommends dnf 2>/dev/null || \
      die "dnf not available — install it or run on a Fedora/RHEL host"
  fi

  dnf \
    --installroot="${ROOTFS}" \
    --releasever="${RELEASE}" \
    --forcearch="${RPM_ARCH}" \
    install -y \
    fedora-release \
    bash \
    coreutils \
    glibc-minimal-langpack

  # Initialize RPM DB in rootfs
  dnf \
    --installroot="${ROOTFS}" \
    --releasever="${RELEASE}" \
    --forcearch="${RPM_ARCH}" \
    makecache
}

install_stage3_packages() {
  dnf install -y \
    gcc gcc-c++ binutils make cmake ninja-build \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python3 python3-pip python3-setuptools \
    golang \
    git curl wget \
    ca-certificates \
    sudo \
    util-linux \
    xz zstd \
    dosfstools \
    kernel-headers
  dnf clean all
}
