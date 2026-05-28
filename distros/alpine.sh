#!/usr/bin/env bash
# distros/alpine.sh — Alpine Linux bootstrap via apk

ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"

# Map Debian arch names to Alpine arch names
declare -A ARCH_MAP=(
  [amd64]=x86_64 [arm64]=aarch64 [armhf]=armhf
  [riscv64]=riscv64 [ppc64el]=ppc64le [s390x]=s390x
  [loong64]=loongarch64 [i386]=x86
)
ALPINE_ARCH="${ARCH_MAP[$ARCH]:-$ARCH}"

# Normalize release: "3.20" → "v3.20", "edge" → "edge"
case "$RELEASE" in
  edge) ALPINE_BRANCH="edge" ;;
  v*)   ALPINE_BRANCH="$RELEASE" ;;
  *)    ALPINE_BRANCH="v${RELEASE}" ;;
esac

do_bootstrap() {
  info "Bootstrapping Alpine ${ALPINE_BRANCH}/${ARCH} via apk"

  local apk_tools_url="${ALPINE_MIRROR}/${ALPINE_BRANCH}/main/${ALPINE_ARCH}"
  local apk_static

  # Fetch apk-tools-static
  apk_static=$(curl -sL "${apk_tools_url}/" \
    | grep -oP 'apk-tools-static-[^"]+\.apk' | tail -1)
  [[ -n "$apk_static" ]] || die "Cannot find apk-tools-static for ${ALPINE_ARCH}"

  curl -sL "${apk_tools_url}/${apk_static}" -o /tmp/apk-tools-static.apk
  tar -xzf /tmp/apk-tools-static.apk -C /tmp sbin/apk.static
  rm -f /tmp/apk-tools-static.apk

  mkdir -p "${ROOTFS}/etc/apk"
  echo "${ALPINE_MIRROR}/${ALPINE_BRANCH}/main"      > "${ROOTFS}/etc/apk/repositories"
  echo "${ALPINE_MIRROR}/${ALPINE_BRANCH}/community" >> "${ROOTFS}/etc/apk/repositories"

  /tmp/sbin/apk.static \
    -X "${ALPINE_MIRROR}/${ALPINE_BRANCH}/main" \
    -U --allow-untrusted \
    --root "${ROOTFS}" \
    --arch "${ALPINE_ARCH}" \
    --initdb \
    add alpine-base

  rm -f /tmp/sbin/apk.static
}

install_stage3_packages() {
  apk update
  apk add --no-cache \
    gcc g++ binutils make cmake samurai \
    autoconf automake libtool pkgconf \
    bison flex patch \
    python3 py3-pip py3-setuptools \
    go \
    git curl wget \
    ca-certificates \
    sudo \
    util-linux \
    xz zstd \
    dosfstools \
    linux-headers
}
