import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

IGNORED_DIRS = {".godot", ".git", "addons", ".import"}
SNAKE_CASE = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*$")
RES_PATH = re.compile(r"res://[^\"')\s]+")


@dataclass(frozen=True)
class Issue:
    severity: str  # "error" or "warning"
    check: str
    path: str
    message: str


def iter_files(root, suffixes):
    root = Path(root)
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix.lower() not in suffixes:
            continue
        if set(p.relative_to(root).parts) & IGNORED_DIRS:
            continue
        yield p


def check_naming(root, suffixes=frozenset({".png", ".ogg", ".wav", ".tscn", ".tres"})):
    root = Path(root)
    issues = []
    for p in iter_files(root, suffixes):
        if not SNAKE_CASE.match(p.stem):
            issues.append(Issue("warning", "naming", str(p.relative_to(root)),
                                "file name should be lowercase snake_case"))
    return issues


def check_png_sizes(root, tile_size=16, max_size=2048):
    root = Path(root)
    issues = []
    for p in iter_files(root, {".png"}):
        with Image.open(p) as img:
            w, h = img.size
        rel = str(p.relative_to(root))
        if max(w, h) > max_size:
            issues.append(Issue("error", "png_size", rel,
                                f"{w}x{h} exceeds max size {max_size}"))
        if w % tile_size or h % tile_size:
            issues.append(Issue("warning", "png_size", rel,
                                f"{w}x{h} is not a multiple of tile size {tile_size}"))
    return issues


def check_references(root):
    root = Path(root)
    issues = []
    for p in iter_files(root, {".tscn", ".tres", ".gd"}):
        text = p.read_text(encoding="utf-8", errors="ignore")
        for ref in sorted(set(RES_PATH.findall(text))):
            if not (root / ref[len("res://"):]).exists():
                # Scripts often build paths dynamically, so only warn there
                severity = "warning" if p.suffix == ".gd" else "error"
                issues.append(Issue(severity, "reference", str(p.relative_to(root)),
                                    f"references missing file {ref}"))
    return issues


def run_all(root, tile_size=16):
    return (check_naming(root)
            + check_png_sizes(root, tile_size=tile_size)
            + check_references(root))


def main(argv=None):
    parser = argparse.ArgumentParser(description="Validate Godot project assets")
    parser.add_argument("root", help="folder containing project.godot")
    parser.add_argument("--tile-size", type=int, default=16)
    parser.add_argument("--strict", action="store_true", help="treat warnings as failures")
    args = parser.parse_args(argv)

    issues = run_all(args.root, tile_size=args.tile_size)
    for i in issues:
        print(f"[{i.severity.upper()}] {i.check}: {i.path}: {i.message}")

    errors = [i for i in issues if i.severity == "error"]
    warnings = [i for i in issues if i.severity == "warning"]
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors or (args.strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())