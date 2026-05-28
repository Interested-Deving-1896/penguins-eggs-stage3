#!/usr/bin/env bash
# distros/arch.sh — Arch Linux bootstrap via pacstrap

ARCH_MIRROR="${ARCH_MIRROR:-https://geo.mirror.pkgbuild.com}"

# Map Debian arch names to Arch Linux arch names
declare -A ARCH_MAP=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armv7h
  [riscv64]=riscv64 [ppc64el]=powerpc64le [i386]=i686
)
ARCH_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"

do_bootstrap() {
  info "Bootstrapping Arch Linux (rolling)/${ARCH} via pacstrap"

  # Install pacstrap if not present
  if ! command -v pacstrap &>/dev/null; then
    if command -v apt-get &>/dev/null; then
      # On Debian/Ubuntu host: bootstrap via Arch bootstrap tarball
      _bootstrap_via_tarball
      return
    fi
    pacman -S --noconfirm arch-install-scripts 2>/dev/null || \
      die "Cannot install pacstrap — run on an Arch host or use Debian/Ubuntu"
  fi

  pacstrap -c "${ROOTFS}" base base-devel
}

_bootstrap_via_tarball() {
  info "Fetching Arch bootstrap tarball for ${ARCH_ARCH}"
  local tarball_url="${ARCH_MIRROR}/iso/latest/archlinux-bootstrap-${ARCH_ARCH}.tar.zst"
  local tarball="/tmp/arch-bootstrap-${ARCH_ARCH}.tar.zst"

  curl -L "$tarball_url" -o "$tarball"
  tar --zstd --strip 1 -xf "$tarball" -C "${ROOTFS}"
  rm -f "$tarball"

  # Set up mirrors
  echo "Server = ${ARCH_MIRROR}/\$repo/os/\$arch" > "${ROOTFS}/etc/pacman.d/mirrorlist"

  # Bootstrap pacman inside the chroot
  chroot "${ROOTFS}" bash -c "
    pacman-key --init
    pacman-key --populate
    pacman -Syu --noconfirm
    pacman -S --noconfirm base base-devel
  "
}

install_stage3_packages() {
  pacman -Syu --noconfirm
  pacman -S --noconfirm --needed \
    gcc binutils make cmake ninja \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python python-pip python-setuptools \
    go \
    git curl wget \
    ca-certificates \
    sudo \
    util-linux \
    xz zstd \
    dosfstools
  pacman -Scc --noconfirm
}
