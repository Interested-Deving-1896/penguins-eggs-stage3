#!/usr/bin/env bash
# eggs/install-eggs.sh — install penguins-eggs into a stage3 rootfs
#
# Called from build-naked.sh after the stage3 is extracted.
# Installs eggs and its runtime dependencies, then runs `eggs config`.
#
# Variables available: DISTRO RELEASE ARCH ROOTFS EGGS_VERSION EGGS_BRANCH

set -euo pipefail

EGGS_VERSION="${EGGS_VERSION:-latest}"
EGGS_BRANCH="${EGGS_BRANCH:-all-features}"
EGGS_REPO="${EGGS_REPO:-https://github.com/Interested-Deving-1896/penguins-eggs}"

info() { echo "[eggs-install] $*"; }

# ── Detect package manager from distro ───────────────────────────────────────
detect_pm() {
  if   chroot "${ROOTFS}" which apt-get  &>/dev/null; then echo "apt"
  elif chroot "${ROOTFS}" which pacman   &>/dev/null; then echo "pacman"
  elif chroot "${ROOTFS}" which dnf      &>/dev/null; then echo "dnf"
  elif chroot "${ROOTFS}" which apk      &>/dev/null; then echo "apk"
  elif chroot "${ROOTFS}" which xbps-install &>/dev/null; then echo "xbps"
  elif chroot "${ROOTFS}" which zypper   &>/dev/null; then echo "zypper"
  elif chroot "${ROOTFS}" which emerge   &>/dev/null; then echo "portage"
  else echo "unknown"
  fi
}

# ── Install Node.js (eggs runtime dependency) ─────────────────────────────────
install_nodejs() {
  local pm="$1"
  info "Installing Node.js via ${pm}"
  case "$pm" in
    apt)
      chroot "${ROOTFS}" bash -c "
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
      "
      ;;
    pacman)
      chroot "${ROOTFS}" pacman -S --noconfirm nodejs npm
      ;;
    dnf)
      chroot "${ROOTFS}" dnf install -y nodejs npm
      ;;
    apk)
      chroot "${ROOTFS}" apk add --no-cache nodejs npm
      ;;
    xbps)
      chroot "${ROOTFS}" xbps-install -y nodejs
      ;;
    zypper)
      chroot "${ROOTFS}" zypper --non-interactive install -y nodejs npm
      ;;
    portage)
      chroot "${ROOTFS}" emerge --noreplace net-libs/nodejs
      ;;
  esac
}

# ── Install eggs runtime dependencies ────────────────────────────────────────
install_eggs_deps() {
  local pm="$1"
  info "Installing eggs runtime dependencies via ${pm}"
  case "$pm" in
    apt)
      chroot "${ROOTFS}" bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y --no-install-recommends \
          squashfs-tools \
          xorriso \
          isolinux \
          syslinux-common \
          grub-efi-amd64-bin \
          grub-pc-bin \
          mtools \
          rsync \
          live-boot \
          live-boot-initramfs-tools \
          initramfs-tools \
          linux-image-generic 2>/dev/null || \
        apt-get install -y --no-install-recommends \
          squashfs-tools xorriso isolinux syslinux-common mtools rsync
      "
      ;;
    pacman)
      chroot "${ROOTFS}" pacman -S --noconfirm \
        squashfs-tools xorriso syslinux mtools rsync
      ;;
    dnf)
      chroot "${ROOTFS}" dnf install -y \
        squashfs-tools xorriso syslinux mtools rsync
      ;;
    apk)
      chroot "${ROOTFS}" apk add --no-cache \
        squashfs-tools xorriso syslinux mtools rsync
      ;;
    *)
      info "Warning: no eggs deps recipe for ${pm} — install manually"
      ;;
  esac
}

# ── Install penguins-eggs itself ──────────────────────────────────────────────
install_eggs_binary() {
  info "Installing penguins-eggs (${EGGS_VERSION})"

  if [[ "$EGGS_VERSION" == "latest" ]]; then
    # Fetch latest release tag
    EGGS_VERSION=$(curl -sL \
      "https://api.github.com/repos/Interested-Deving-1896/penguins-eggs/releases/latest" \
      | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null \
      || echo "latest")
  fi

  # Try npm install first (works on all distros with Node.js)
  if chroot "${ROOTFS}" which npm &>/dev/null; then
    chroot "${ROOTFS}" npm install -g penguins-eggs 2>/dev/null || \
      _install_eggs_from_source
  else
    _install_eggs_from_source
  fi
}

_install_eggs_from_source() {
  info "Installing eggs from source (${EGGS_BRANCH} branch)"
  chroot "${ROOTFS}" bash -c "
    git clone --depth=1 --branch ${EGGS_BRANCH} ${EGGS_REPO} /opt/penguins-eggs
    cd /opt/penguins-eggs
    npm install --production
    npm run build 2>/dev/null || true
    ln -sf /opt/penguins-eggs/bin/eggs /usr/local/bin/eggs
  "
}

# ── Configure eggs ────────────────────────────────────────────────────────────
configure_eggs() {
  info "Running eggs config --nointeractive"
  chroot "${ROOTFS}" bash -c "
    eggs config --nointeractive 2>/dev/null || \
    eggs config 2>/dev/null || \
    echo 'eggs config skipped — run manually after boot'
  " || true
}

# ── Main ──────────────────────────────────────────────────────────────────────
PM=$(detect_pm)
info "Package manager: ${PM}"

install_nodejs "$PM"
install_eggs_deps "$PM"
install_eggs_binary
configure_eggs

info "penguins-eggs installed in ${ROOTFS}"
chroot "${ROOTFS}" eggs --version 2>/dev/null || true
