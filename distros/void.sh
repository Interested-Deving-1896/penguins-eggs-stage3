#!/usr/bin/env bash
# distros/void.sh — Void Linux bootstrap via xbps-install

VOID_MIRROR="${VOID_MIRROR:-https://repo-default.voidlinux.org}"

# Map Debian arch names to Void arch names
# Void uses musl or glibc variants; default to glibc
declare -A ARCH_MAP=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armv7l
  [ppc64el]=ppc64le [i386]=i686
)
VOID_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"
VOID_LIBC="${VOID_LIBC:-glibc}"  # or musl

# Void repo path differs by libc
if [[ "$VOID_LIBC" == "musl" ]]; then
  VOID_REPO="${VOID_MIRROR}/current/musl"
else
  VOID_REPO="${VOID_MIRROR}/current"
fi

do_bootstrap() {
  info "Bootstrapping Void Linux (${VOID_LIBC})/${ARCH} via xbps-install"

  # Fetch xbps-static
  local xbps_url="${VOID_MIRROR}/static"
  local xbps_tarball
  xbps_tarball=$(curl -sL "${xbps_url}/" \
    | grep -oP "xbps-static-[^\"]+\\.${VOID_ARCH}\\.tar\\.xz" | tail -1)
  [[ -n "$xbps_tarball" ]] || die "Cannot find xbps-static for ${VOID_ARCH}"

  curl -sL "${xbps_url}/${xbps_tarball}" -o /tmp/xbps-static.tar.xz
  tar -xJf /tmp/xbps-static.tar.xz -C /tmp
  rm -f /tmp/xbps-static.tar.xz

  local xbps_install
  xbps_install=$(find /tmp -name "xbps-install.static" | head -1)
  [[ -n "$xbps_install" ]] || die "xbps-install.static not found after extraction"

  # Fetch Void keyring
  mkdir -p "${ROOTFS}/var/db/xbps/keys"
  curl -sL "${VOID_REPO}/void-repo-keys-0.1_1.${VOID_ARCH}.xbps" \
    -o /tmp/void-keys.xbps 2>/dev/null || true

  "$xbps_install" \
    -r "${ROOTFS}" \
    -R "${VOID_REPO}" \
    --arch "${VOID_ARCH}" \
    -S \
    base-system

  rm -f "$xbps_install"
}

install_stage3_packages() {
  xbps-install -Syu
  xbps-install -y \
    gcc binutils make cmake ninja \
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
    linux-headers
  xbps-remove -Oo
}
