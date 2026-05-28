#!/usr/bin/env bash
# build.sh — build a minimal Linux stage3 tarball for any distro + arch
#
# Usage:
#   sudo ./build.sh --distro debian --release trixie --arch amd64
#   sudo ./build.sh --distro arch   --release rolling --arch arm64
#   sudo ./build.sh --distro alpine --release 3.20    --arch riscv64
#
# Output: {distro}_stage3_{release}_{arch}_{date}.tar.gz
#
# Supported distros: debian ubuntu devuan arch fedora alpine void opensuse gentoo
# Supported arches:  amd64 arm64 armhf riscv64 ppc64el s390x loong64 i386
#
# Cross-arch builds use QEMU binfmt_misc (installed automatically).
# Native builds skip QEMU entirely.

set -euo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
DISTRO="${DISTRO:-debian}"
RELEASE="${RELEASE:-trixie}"
ARCH="${ARCH:-amd64}"
ROOTFS="$(pwd)/rootfs"
OUTPUT_DIR="$(pwd)"
JOBS="${JOBS:-$(nproc)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro)   DISTRO="$2";   shift 2 ;;
    --release)  RELEASE="$2";  shift 2 ;;
    --arch)     ARCH="$2";     shift 2 ;;
    --output)   OUTPUT_DIR="$2"; shift 2 ;;
    --jobs)     JOBS="$2";     shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── validation ────────────────────────────────────────────────────────────────
SUPPORTED_DISTROS=(debian ubuntu devuan arch fedora alpine void opensuse gentoo)
SUPPORTED_ARCHES=(amd64 arm64 armhf riscv64 ppc64el s390x loong64 i386)

distro_ok=false; for d in "${SUPPORTED_DISTROS[@]}"; do [[ "$d" == "$DISTRO" ]] && distro_ok=true; done
arch_ok=false;   for a in "${SUPPORTED_ARCHES[@]}";  do [[ "$a" == "$ARCH"   ]] && arch_ok=true;   done

$distro_ok || { echo "Unsupported distro: $DISTRO. Supported: ${SUPPORTED_DISTROS[*]}" >&2; exit 1; }
$arch_ok   || { echo "Unsupported arch: $ARCH. Supported: ${SUPPORTED_ARCHES[*]}" >&2; exit 1; }

[[ $EUID -eq 0 ]] || { echo "Must run as root (sudo ./build.sh ...)" >&2; exit 1; }

# ── helpers ───────────────────────────────────────────────────────────────────
info()  { echo "[stage3] $*"; }
die()   { echo "[stage3] ERROR: $*" >&2; exit 1; }

cleanup() {
  info "Cleaning up mounts..."
  for mnt in proc sys dev/pts dev; do
    mountpoint -q "${ROOTFS}/${mnt}" 2>/dev/null && umount -l "${ROOTFS}/${mnt}" || true
  done
}
trap cleanup EXIT

# ── QEMU cross-arch setup ─────────────────────────────────────────────────────
HOST_ARCH="$(uname -m)"

# Map Debian arch names to uname -m names
declare -A ARCH_TO_UNAME=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armv7l
  [riscv64]=riscv64 [ppc64el]=ppc64le [s390x]=s390x
  [loong64]=loongarch64 [i386]=i686
)
TARGET_UNAME="${ARCH_TO_UNAME[$ARCH]}"

setup_qemu() {
  if [[ "$TARGET_UNAME" == "$HOST_ARCH" ]] || \
     [[ "$TARGET_UNAME" == "x86_64" && "$HOST_ARCH" == "x86_64" ]]; then
    info "Native build — skipping QEMU"
    return 0
  fi

  info "Cross-arch build: host=$HOST_ARCH target=$ARCH — setting up QEMU"
  apt-get install -y --no-install-recommends qemu-user-static binfmt-support 2>/dev/null || \
    dnf install -y qemu-user-static 2>/dev/null || \
    pacman -S --noconfirm qemu-user-static 2>/dev/null || \
    die "Cannot install qemu-user-static — install it manually"

  update-binfmts --enable 2>/dev/null || systemctl restart systemd-binfmt 2>/dev/null || true
  info "QEMU binfmt registered"
}

# ── mount helpers ─────────────────────────────────────────────────────────────
mount_pseudo() {
  mount -t proc  none          "${ROOTFS}/proc"
  mount --bind   /sys          "${ROOTFS}/sys"
  mount --make-slave           "${ROOTFS}/sys"
  mount --bind   /dev          "${ROOTFS}/dev"
  mount --make-slave           "${ROOTFS}/dev"
  mount --bind   /dev/pts      "${ROOTFS}/dev/pts"
  mount --make-slave           "${ROOTFS}/dev/pts"
}

# ── distro bootstrap dispatch ─────────────────────────────────────────────────
bootstrap() {
  local distro_script="${SCRIPT_DIR}/distros/${DISTRO}.sh"
  [[ -f "$distro_script" ]] || die "No bootstrap script for distro: $DISTRO"
  # shellcheck source=/dev/null
  source "$distro_script"
  do_bootstrap
}

# ── package install (inside chroot) ──────────────────────────────────────────
install_packages() {
  local distro_script="${SCRIPT_DIR}/distros/${DISTRO}.sh"
  source "$distro_script"
  info "Installing stage3 package set..."
  chroot "${ROOTFS}" bash -c "$(declare -f install_stage3_packages); install_stage3_packages"
}

# ── finalize ──────────────────────────────────────────────────────────────────
finalize() {
  # Copy QEMU binary into rootfs for cross-arch chroot operations
  if [[ "$TARGET_UNAME" != "$HOST_ARCH" ]]; then
    local qemu_bin
    qemu_bin=$(find /usr/bin -name "qemu-${TARGET_UNAME}-static" 2>/dev/null | head -1)
    [[ -n "$qemu_bin" ]] && cp "$qemu_bin" "${ROOTFS}/usr/bin/"
  fi

  # Inject resolv.conf
  echo 'nameserver 1.1.1.1' > "${ROOTFS}/etc/resolv.conf"

  mount_pseudo
  install_packages
  cleanup

  # Remove QEMU binary from final tarball
  rm -f "${ROOTFS}/usr/bin/qemu-"*"-static"

  # Strip resolv.conf
  rm -f "${ROOTFS}/etc/resolv.conf"
}

# ── package ───────────────────────────────────────────────────────────────────
package() {
  local date_str
  date_str=$(date +"%Y%m%d")
  local tarball="${OUTPUT_DIR}/${DISTRO}_stage3_${RELEASE}_${ARCH}_${date_str}.tar.gz"

  info "Packaging → ${tarball}"
  tar --numeric-owner -czf "$tarball" -C "${ROOTFS}" .
  sha256sum "$tarball" > "${tarball}.sha256"
  info "Done: $(du -sh "$tarball" | cut -f1)"
}

# ── main ──────────────────────────────────────────────────────────────────────
info "Building ${DISTRO}/${RELEASE}/${ARCH} stage3"

rm -rf "${ROOTFS}"
mkdir -p "${ROOTFS}"

setup_qemu
bootstrap
finalize
package

info "Stage3 complete: ${DISTRO}_stage3_${RELEASE}_${ARCH}_$(date +%Y%m%d).tar.gz"
