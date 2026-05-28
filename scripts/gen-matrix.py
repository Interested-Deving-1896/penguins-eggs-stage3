#!/usr/bin/env python3
"""gen-matrix.py — generate GitHub Actions build matrix from config/matrix.yml

Usage:
  python3 scripts/gen-matrix.py [--distro DISTRO] [--arch ARCH]
                                 [--release RELEASE] [--tier 1|2|3]

Outputs JSON: {"include": [{distro, release, arch, tier}, ...]}
"""
import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    # Minimal YAML parser for simple key: value structures
    # Falls back to a bundled parser if PyYAML is not installed
    yaml = None


def load_matrix(path: Path) -> dict:
    text = path.read_text()
    if yaml:
        return yaml.safe_load(text)
    # Minimal fallback: parse with json after stripping comments
    # (only works for trivial YAML — install PyYAML for production use)
    raise RuntimeError(
        "PyYAML not installed. Run: pip3 install pyyaml\n"
        "Or: apt-get install python3-yaml"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--distro",  default="")
    parser.add_argument("--arch",    default="")
    parser.add_argument("--release", default="")
    parser.add_argument("--tier",    type=int, default=1)
    args = parser.parse_args()

    matrix_path = Path(__file__).parent.parent / "config" / "matrix.yml"
    config = load_matrix(matrix_path)

    includes = []

    for distro_name, distro_cfg in config["distros"].items():
        # Filter by distro if specified
        if args.distro and distro_name != args.distro:
            continue

        releases = distro_cfg["releases"]
        default_release = distro_cfg["default_release"]

        # Filter by release if specified
        if args.release:
            if args.release not in releases:
                continue
            releases = [args.release]
        else:
            # On tier 1 builds, only use the default release
            if args.tier == 1:
                releases = [default_release]

        for arch, arch_cfg in distro_cfg["arches"].items():
            # Filter by arch if specified
            if args.arch and arch != args.arch:
                continue

            tier = arch_cfg.get("tier", 1)
            if tier > args.tier:
                continue

            for release in releases:
                includes.append({
                    "distro":  distro_name,
                    "release": str(release),
                    "arch":    arch,
                    "tier":    tier,
                })

    result = {"include": includes}
    print(json.dumps(result))


if __name__ == "__main__":
    main()
