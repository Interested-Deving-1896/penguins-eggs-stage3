#!/usr/bin/env bash
# distros/gentoo.sh — Gentoo bootstrap via official stage3 tarball
# Gentoo already distributes stage3 tarballs — we fetch the official one
# and layer our standard package set on top via emerge.

GENTOO_MIRROR="${GENTOO_MIRROR:-https://distfiles.gentoo.org}"

# Map Debian arch names to Gentoo arch names
declare -A ARCH_MAP=(
  [amd64]=amd64 [arm64]=arm64 [armhf]=armv7a
  [riscv64]=rv64_lp64d [ppc64el]=ppc64le [s390x]=s390x
  [loong64]=loong64 [i386]=x86
)
GENTOO_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"

# Profile variant: openrc (systemd-free) by default
GENTOO_PROFILE="${GENTOO_PROFILE:-openrc}"

do_bootstrap() {
  info "Bootstrapping Gentoo (${GENTOO_PROFILE})/${ARCH} via official stage3 tarball"

  local latest_url="${GENTOO_MIRROR}/releases/${GENTOO_ARCH}/autobuilds"
  local latest_file

  # Find the latest stage3 tarball URL
  case "$GENTOO_PROFILE" in
    openrc)   latest_file="latest-stage3-${GENTOO_ARCH}-openrc.txt" ;;
    systemd)  latest_file="latest-stage3-${GENTOO_ARCH}-systemd.txt" ;;
    musl)     latest_file="latest-stage3-${GENTOO_ARCH}-musl.txt" ;;
    *)        latest_file="latest-stage3-${GENTOO_ARCH}-openrc.txt" ;;
  esac

  local latest_txt
  latest_txt=$(curl -sL "${latest_url}/${latest_file}") || \
    die "Cannot fetch ${latest_url}/${latest_file}"

  local tarball_path
  tarball_path=$(echo "$latest_txt" | grep -v '^#' | grep '\.tar\.' | head -1 | awk '{print $1}')
  [[ -n "$tarball_path" ]] || die "Cannot parse stage3 tarball path from ${latest_file}"

  local tarball_url="${latest_url}/${tarball_path}"
  local tarball="/tmp/gentoo-stage3.tar.xz"

  info "Fetching ${tarball_url}"
  curl -L "$tarball_url" -o "$tarball"

  info "Extracting Gentoo stage3..."
  tar xpf "$tarball" \
    --xattrs-include='*.*' \
    --numeric-owner \
    -C "${ROOTFS}"
  rm -f "$tarball"

  # Configure portage mirrors
  mkdir -p "${ROOTFS}/etc/portage"
  echo "GENTOO_MIRRORS=\"${GENTOO_MIRROR}\"" >> "${ROOTFS}/etc/portage/make.conf"
  echo "MAKEOPTS=\"-j${JOBS}\"" >> "${ROOTFS}/etc/portage/make.conf"
}

install_stage3_packages() {
  # Sync portage tree
  emerge-webrsync

  # Install standard stage3 package set
  emerge --noreplace --quiet \
    sys-devel/gcc \
    sys-devel/binutils \
    dev-build/make \
    dev-build/cmake \
    dev-build/ninja \
    sys-devel/autoconf \
    sys-devel/automake \
    dev-build/libtool \
    dev-util/pkgconf \
    sys-devel/bison \
    sys-devel/flex \
    sys-devel/patch \
    dev-lang/python \
    dev-python/pip \
    dev-lang/go \
    dev-vcs/git \
    net-misc/curl \
    net-misc/wget \
    app-misc/ca-certificates \
    app-admin/sudo \
    sys-apps/util-linux \
    app-arch/xz-utils \
    app-arch/zstd \
    sys-fs/dosfstools \
    sys-kernel/linux-headers

  emerge --depclean --quiet
}
