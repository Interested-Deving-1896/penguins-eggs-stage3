#!/usr/bin/env bash
# build-naked.sh — build a penguins-eggs naked base image for any distro + arch
#
# Extends linux-distro-stage3/build.sh with two additional steps:
#   1. Install penguins-eggs into the stage3 rootfs
#   2. Produce a naked base ISO with `eggs produce --naked`
#
# Usage:
#   sudo ./build-naked.sh --distro debian --release trixie --arch amd64
#   sudo ./build-naked.sh --distro alpine --release 3.21   --arch arm64
#   sudo ./build-naked.sh --distro devuan --release excalibur --arch armhf
#
# Output:
#   {distro}_stage3_{release}_{arch}_{date}.tar.gz   — stage3 tarball
#   {distro}-{release}-{arch}-naked-{date}.iso        — naked base ISO (if produced)
#
# Environment variables:
#   EGGS_VERSION   — penguins-eggs version to install (default: latest)
#   EGGS_BRANCH    — branch to clone from source (default: all-features)
#   SKIP_ISO       — set to 1 to skip ISO production (stage3 only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse args (pass-through to build.sh) ────────────────────────────────────
DISTRO="${DISTRO:-debian}"
RELEASE="${RELEASE:-trixie}"
ARCH="${ARCH:-amd64}"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"
SKIP_ISO="${SKIP_ISO:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --distro)   DISTRO="$2";   shift 2 ;;
    --release)  RELEASE="$2";  shift 2 ;;
    --arch)     ARCH="$2";     shift 2 ;;
    --output)   OUTPUT_DIR="$2"; shift 2 ;;
    --skip-iso) SKIP_ISO=1;    shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

export DISTRO RELEASE ARCH OUTPUT_DIR

[[ $EUID -eq 0 ]] || { echo "Must run as root (sudo ./build-naked.sh ...)" >&2; exit 1; }

info() { echo "[penguins-eggs-stage3] $*"; }

# ── Step 1: Build the base stage3 ────────────────────────────────────────────
info "=== Step 1: Build ${DISTRO}/${RELEASE}/${ARCH} stage3 ==="
bash "${SCRIPT_DIR}/build.sh" \
  --distro  "$DISTRO" \
  --release "$RELEASE" \
  --arch    "$ARCH" \
  --output  "$OUTPUT_DIR"

ROOTFS="${SCRIPT_DIR}/rootfs"

# ── Step 2: Install penguins-eggs ────────────────────────────────────────────
info "=== Step 2: Install penguins-eggs ==="
export ROOTFS
bash "${SCRIPT_DIR}/eggs/install-eggs.sh"

# ── Step 3: Produce naked ISO ─────────────────────────────────────────────────
if [[ "$SKIP_ISO" == "1" ]]; then
  info "=== Step 3: Skipped (--skip-iso) ==="
else
  info "=== Step 3: Produce naked base ISO ==="
  bash "${SCRIPT_DIR}/eggs/naked-image.sh"
fi

info "Build complete"
info "Stage3: ${OUTPUT_DIR}/${DISTRO}_stage3_${RELEASE}_${ARCH}_$(date +%Y%m%d).tar.gz"
[[ "$SKIP_ISO" == "1" ]] || \
  info "ISO:    ${OUTPUT_DIR}/${DISTRO}-${RELEASE}-${ARCH}-naked-*.iso (if produced)"
