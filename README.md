# linux-distro-stage3

Distro-agnostic, architecture-agnostic Linux stage3 builder.

Produces minimal bootable root filesystem tarballs for any supported distro/arch combination. Each tarball contains a compiler toolchain, build tools, and essential utilities — nothing more.

Forked from [chromiumos-stage3](https://github.com/Interested-Deving-1896/chromiumos-stage3) and generalized: the ChromiumOS-specific `cros_sdk`/Portage bootstrap is replaced with native distro tooling (`debootstrap`, `pacstrap`, `dnf`, `apk`, `xbps-install`, `zypper`, Gentoo stage3 tarballs).

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

✅ Tier 1/2 — built in CI &nbsp; 🧪 Tier 3 — experimental, manual only &nbsp; — Not supported

Cross-arch builds use QEMU `binfmt_misc` on an amd64 host.

## Usage

```bash
# Build Debian trixie for amd64 (native)
sudo ./build.sh --distro debian --release trixie --arch amd64

# Build Alpine 3.21 for arm64 (cross via QEMU)
sudo ./build.sh --distro alpine --release 3.21 --arch arm64

# Build Devuan excalibur for riscv64
sudo ./build.sh --distro devuan --release excalibur --arch riscv64
```

Output: `{distro}_stage3_{release}_{arch}_{date}.tar.gz`

### Requirements

- Root access
- 10 GB free disk space per build
- `curl`, `git`, `xz-utils`, `zstd`
- For cross-arch: `qemu-user-static`, `binfmt-support`
- Distro-specific: `debootstrap` (Debian/Ubuntu/Devuan), `pacstrap` (Arch), `dnf` (Fedora), `apk` (Alpine), `xbps-install` (Void), `zypper` (openSUSE)

## Stage3 package set

Every stage3 tarball contains:

| Category | Packages |
|----------|----------|
| Compiler | gcc, g++, binutils |
| Build | make, cmake, ninja, autoconf, automake, libtool, pkg-config |
| Languages | python3, pip, go |
| Parse/gen | bison, flex, patch |
| VCS/net | git, curl, wget |
| System | sudo, util-linux, ca-certificates |
| Compression | xz, zstd |
| Filesystem | dosfstools |
| Headers | linux-headers |

## CI

GitHub Actions builds the tier 1 matrix (default release × amd64/arm64/armhf) weekly and on every push to `main`. Tier 2 arches build on schedule. Tier 3 is manual-only via `workflow_dispatch`.

Artifacts are published as GitHub Releases tagged `stage3-YYYYMMDD`.

## Fork: penguins-eggs-stage3

[penguins-eggs-stage3](https://github.com/Interested-Deving-1896/penguins-eggs-stage3) extends each stage3 with:
- penguins-eggs installation
- Naked base image builds (`eggs produce --naked`)
- Integration with the penguins-eggs `all-features` branch

## Architecture

```
linux-distro-stage3/
├── build.sh                  # Main entry point
├── distros/
│   ├── debian.sh             # debootstrap bootstrap + package install
│   ├── ubuntu.sh
│   ├── devuan.sh
│   ├── arch.sh               # pacstrap / Arch bootstrap tarball
│   ├── fedora.sh             # dnf --installroot
│   ├── alpine.sh             # apk-static
│   ├── void.sh               # xbps-install
│   ├── opensuse.sh           # zypper --root
│   └── gentoo.sh             # official stage3 tarball + emerge
├── config/
│   └── matrix.yml            # distro × arch support matrix
├── scripts/
│   └── gen-matrix.py         # CI matrix generator
└── .github/workflows/
    └── build.yml             # CI: matrix build + release
```
