[update-readmes]   Mode: rewrite — migrating to template structure...
# penguins-eggs-stage3

[![Built with Ona](https://ona.com/build-with-ona.svg)](https://app.ona.com/#https://github.com/Interested-Deving-1896/penguins-eggs-stage3)

<!-- AI:start:what-it-does -->
_Description pending._
<!-- AI:end:what-it-does -->

## Architecture

<!-- AI:start:architecture -->
_Architecture documentation pending._
<!-- AI:end:architecture -->

## Install

<!-- Add installation instructions here. This section is yours — the AI will not modify it. -->

```bash
git clone https://github.com/Interested-Deving-1896/penguins-eggs-stage3.git
cd penguins-eggs-stage3
```

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

## Configuration

<!-- Document configuration options here. This section is yours — the AI will not modify it. -->

## CI

<!-- AI:start:ci -->
_CI documentation pending._
<!-- AI:end:ci -->

## Mirror chain

<!-- AI:start:mirror-chain -->
This repo is maintained in [`Interested-Deving-1896/penguins-eggs-stage3`](https://github.com/Interested-Deving-1896/penguins-eggs-stage3) and mirrored through:

```
Interested-Deving-1896/penguins-eggs-stage3  ──►  OpenOS-Project-OSP/penguins-eggs-stage3  ──►  OpenOS-Project-Ecosystem-OOC/penguins-eggs-stage3
```

Changes flow downstream automatically via the hourly mirror chain in
[`fork-sync-all`](https://github.com/Interested-Deving-1896/fork-sync-all).
Direct commits to OSP or OOC are detected and opened as PRs back to `Interested-Deving-1896`.
<!-- AI:end:mirror-chain -->

## Contributors

<!-- AI:start:contributors -->
_Contributors pending._
<!-- AI:end:contributors -->

## Origins

<!-- AI:start:origins -->
_Original project — no upstream fork._
<!-- AI:end:origins -->

## Resources

<!-- AI:start:resources -->
_No additional resource files found._
<!-- AI:end:resources -->

## License

<!-- AI:start:license -->
<!-- License not detected — add a LICENSE file to this repo. -->
<!-- AI:end:license -->
