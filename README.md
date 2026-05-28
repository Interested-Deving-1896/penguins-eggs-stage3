# penguins-eggs-stage3

Debian/Ubuntu/Devuan/Arch/Fedora/Alpine/Void/openSUSE/Gentoo stage3 builder with penguins-eggs integration.

Extends [linux-distro-stage3](https://github.com/Interested-Deving-1896/linux-distro-stage3) with two additional steps:
1. Install [penguins-eggs](https://github.com/Interested-Deving-1896/penguins-eggs) (`all-features` branch) into the stage3 rootfs
2. Produce a **naked base ISO** with `eggs produce --naked`

A naked base ISO is a minimal live image — kernel + initramfs + base system + penguins-eggs, no desktop. Boot it, add packages, then run `eggs produce` to remaster into a custom distro ISO.

## Supported distros and architectures

| Distro | amd64 | arm64 | armhf | riscv64 | ppc64el | s390x | loong64 | i386 |
|--------|:-----:|:-----:|:-----:|:-------:|:-------:|:-----:|:-------:|:----:|
| Debian (trixie/bookworm/sid) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🧪 | ✅ |
| Ubuntu (noble/jammy/oracular) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | 🧪 |
| Devuan (excalibur/daedalus/ceres) | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | ✅ |
| Arch Linux (rolling) | ✅ | ✅ | ✅ | 🧪 | — | — | — | 🧪 |
| Fedora (42/41/rawhide) | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | ✅ |
| Alpine (3.21/3.20/edge) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 🧪 | ✅ |
| Void Linux (rolling) | ✅ | ✅ | ✅ | — | ✅ | — | — | ✅ |
| openSUSE (tumbleweed/15.6) | ✅ | ✅ | ✅ | — | ✅ | ✅ | — | ✅ |
| Gentoo (rolling) | ✅ | ✅ | ✅ | ✅ | ✅ | 🧪 | 🧪 | ✅ |

✅ Tier 1/2 — built in CI &nbsp; 🧪 Tier 3 — experimental &nbsp; — Not supported

## Usage

```bash
# Full build: stage3 + eggs install + naked ISO
sudo ./build-naked.sh --distro debian --release trixie --arch amd64

# Stage3 + eggs install only (skip ISO production)
sudo ./build-naked.sh --distro alpine --release 3.21 --arch arm64 --skip-iso

# Stage3 only (no eggs)
sudo ./build.sh --distro devuan --release excalibur --arch armhf
```

### Requirements

- Root access, 15 GB free disk space
- `debootstrap`, `qemu-user-static`, `binfmt-support`, `squashfs-tools`, `xorriso`

## Outputs

| File | Description |
|------|-------------|
| `{distro}_stage3_{release}_{arch}_{date}.tar.gz` | Minimal rootfs + penguins-eggs |
| `{distro}-{release}-{arch}-naked-{date}.iso` | Bootable naked base ISO |
| `*.sha256` | SHA-256 checksums |

## Naked base image workflow

```
stage3 tarball
    └── install penguins-eggs (all-features branch)
        └── eggs config --nointeractive
            └── eggs produce --naked
                └── {distro}-{release}-{arch}-naked.iso
                        └── boot → customize → eggs produce → custom ISO
```

## Integration with penguins-eggs all-features

The `eggs stage3` command (added to the `all-features` branch) wraps this build pipeline:

```bash
# From a running penguins-eggs system:
eggs stage3 --distro debian --release trixie --arch arm64
```

See [integrations/plugins/build-infra/penguins-eggs-stage3/](https://github.com/Interested-Deving-1896/penguins-eggs/tree/all-features/integrations/plugins/build-infra/penguins-eggs-stage3) for the plugin source.

## Architecture

```
penguins-eggs-stage3/
├── build.sh                  # Stage3 builder (from linux-distro-stage3)
├── build-naked.sh            # Orchestrator: stage3 → eggs install → naked ISO
├── eggs/
│   ├── install-eggs.sh       # Install penguins-eggs into rootfs
│   └── naked-image.sh        # Run eggs produce --naked
├── distros/                  # Per-distro bootstrap scripts
├── config/matrix.yml         # Distro × arch support matrix
├── scripts/gen-matrix.py     # CI matrix generator
└── .github/workflows/
    └── build.yml             # CI: matrix build + release
```
