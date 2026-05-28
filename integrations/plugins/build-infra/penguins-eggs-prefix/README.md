# penguins-eggs-prefix integration

This plugin documents how [penguins-eggs-prefix](https://github.com/Interested-Deving-1896/penguins-eggs-prefix)
relates to penguins-eggs-stage3.

## Relationship

```
penguins-eggs-stage3  -->  penguins-eggs (--stage3)
                                |
penguins-eggs-prefix  -->  penguins-eggs (--prefix)
```

Both repos feed into penguins-eggs as alternative rootfs sources:

- **penguins-eggs-stage3**: provides a minimal distro rootfs (kernel + base packages).
  Used with `eggs produce --stage3` to build a live ISO from a fresh stage3.
- **penguins-eggs-prefix**: provides a Gentoo prefix with ISO production tools.
  Used with `eggs produce --prefix` to build a live ISO from a Gentoo prefix.

They are independent pipelines — you can use either or both.

## Combined workflow

To build a Gentoo-prefix-based ISO on top of a stage3 rootfs:

1. Build a stage3 with penguins-eggs-stage3:
   ```bash
   sudo ./build.sh --distro debian --release trixie --arch amd64
   ```

2. Pass the stage3 tarball to penguins-eggs-prefix to skip the chroot bootstrap:
   ```bash
   sudo ./build.sh \
     --distro debian --arch amd64 \
     --stage3 ./debian_stage3_trixie_amd64_YYYYMMDD.tar.gz \
     --iso
   ```

3. The resulting ISO contains the Gentoo prefix installed into the stage3 rootfs.

## CI schedule alignment

| Repo | Schedule | Rationale |
|------|----------|-----------|
| linux-distro-stage3 | Monthly, 1st | Base stage3 tarballs |
| penguins-eggs-stage3 | Monthly, 1st+1d | penguins-eggs stage3 tarballs |
| linux-distro-prefix | Monthly, 2nd | Base Gentoo prefix tarballs |
| penguins-eggs-prefix | Monthly, 3rd | penguins-eggs prefix tarballs + ISOs |
