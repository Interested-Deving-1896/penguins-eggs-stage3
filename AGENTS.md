# AGENTS.md — penguins-eggs-stage3

## Purpose

Extends linux-distro-stage3 with penguins-eggs installation and naked base image production.
Each build produces a stage3 tarball (rootfs + eggs) and optionally a naked live ISO.

Upstream: [linux-distro-stage3](https://github.com/Interested-Deving-1896/linux-distro-stage3)
Integrated into: [penguins-eggs all-features](https://github.com/Interested-Deving-1896/penguins-eggs/tree/all-features)

## Repository layout

```
build.sh              Stage3 builder (inherited from linux-distro-stage3)
build-naked.sh        Orchestrator: stage3 → eggs install → naked ISO
eggs/
  install-eggs.sh     Install penguins-eggs into $ROOTFS via chroot
  naked-image.sh      Run eggs produce --naked inside $ROOTFS
distros/              Per-distro bootstrap scripts (inherited)
config/matrix.yml     Distro × arch support matrix (inherited)
scripts/gen-matrix.py CI matrix generator (inherited)
```

## Build pipeline

```
build-naked.sh
  └── build.sh              → {distro}_stage3_{release}_{arch}_{date}.tar.gz
  └── eggs/install-eggs.sh  → penguins-eggs installed in $ROOTFS
  └── eggs/naked-image.sh   → {distro}-{release}-{arch}-naked-{date}.iso
```

## Key design decisions

- `install-eggs.sh` detects the package manager from the chroot (apt/pacman/dnf/apk/xbps/zypper/portage)
- eggs is installed via `npm install -g penguins-eggs` if npm is available; falls back to source clone from `all-features` branch
- `naked-image.sh` mounts /proc /sys /dev inside the chroot, runs `eggs produce --naked`, then unmounts
- ISO production is best-effort — if eggs produce fails (e.g. missing kernel), the stage3 tarball is still valid
- `SKIP_ISO=1` skips ISO production entirely (useful for CI cost control)

## Syncing from linux-distro-stage3

When linux-distro-stage3 adds a new distro or arch:
1. Pull the updated `distros/*.sh` and `config/matrix.yml`
2. Verify `install-eggs.sh` has a package manager case for the new distro
3. Test: `sudo ./build-naked.sh --distro {new} --release {release} --arch amd64 --skip-iso`

## penguins-eggs integration

The `eggs stage3` command in the all-features branch calls `build-naked.sh` via the
`integrations/plugins/build-infra/penguins-eggs-stage3/` plugin. The plugin passes
`--distro`, `--release`, `--arch` from the eggs CLI to this script.
