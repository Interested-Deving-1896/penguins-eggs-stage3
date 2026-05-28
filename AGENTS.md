# AGENTS.md — linux-distro-stage3

## Purpose

Distro-agnostic, architecture-agnostic Linux stage3 builder. Produces minimal
bootable root filesystem tarballs for any supported distro/arch combination.

Upstream: [chromiumos-stage3](https://github.com/Interested-Deving-1896/chromiumos-stage3)
Fork: [penguins-eggs-stage3](https://github.com/Interested-Deving-1896/penguins-eggs-stage3)

## Repository layout

```
build.sh              Main entry point — dispatches to distros/{distro}.sh
distros/              One script per distro: do_bootstrap() + install_stage3_packages()
config/matrix.yml     Distro × arch support matrix (tier 1/2/3)
scripts/gen-matrix.py CI matrix generator — reads matrix.yml, outputs JSON
.github/workflows/    build.yml: matrix build + release
```

## Adding a new distro

1. Create `distros/{name}.sh` with two functions:
   - `do_bootstrap()` — populate `$ROOTFS` with a minimal base system
   - `install_stage3_packages()` — install the standard package set inside the chroot
2. Add the distro to `config/matrix.yml` with its supported arches and tiers
3. Test locally: `sudo ./build.sh --distro {name} --release {release} --arch amd64`

## Adding a new architecture

1. Add the arch to the relevant distros in `config/matrix.yml`
2. Add the arch→uname mapping to `ARCH_TO_UNAME` in `build.sh`
3. Add the arch→distro-native-name mapping in the relevant `distros/*.sh` files
4. Test cross-arch: `sudo ./build.sh --distro debian --release trixie --arch {arch}`

## Naming conventions

- Tarballs: `{distro}_stage3_{release}_{arch}_{YYYYMMDD}.tar.gz`
- Releases: tagged `stage3-YYYYMMDD`
- Arch names follow Debian conventions (amd64, arm64, armhf, riscv64, ppc64el, s390x, loong64, i386)

## Tier definitions

- Tier 1: built in CI on every push + weekly schedule (default release, amd64/arm64/armhf)
- Tier 2: built in CI on weekly schedule only
- Tier 3: experimental — manual `workflow_dispatch` only

## Key constraints

- `build.sh` must run as root (uses `chroot`, `mount`, `unshare`)
- Cross-arch builds require `qemu-user-static` + `binfmt-support` on the host
- Each `distros/*.sh` is sourced (not executed) — no `set -e` at the top level
- `do_bootstrap()` populates `$ROOTFS`; `install_stage3_packages()` runs inside the chroot
- QEMU binary is injected into rootfs for cross-arch chroot, then removed before packaging
- `resolv.conf` is injected before chroot operations, removed before packaging
