#!/usr/bin/env python3
"""Manage dev configs in this repo.

    python3 dot.py status [NAME...]        what differs between the system and the repo
    python3 dot.py diff   [NAME...]        show the actual differences
    python3 dot.py save   [NAME...]        copy configs from the system into the repo
    python3 dot.py apply  [NAME...]        copy configs from the repo onto the system
    python3 dot.py add NAME PATH [-i GLOB...] [-x GLOB...]
                                           start tracking a new config

The tracked configs live in dotfiles.json. Each entry has a system path per
platform (windows / linux / macos); paths may use ~ and environment variables
like $APPDATA or $SCOOP. A path may be a single file or a directory; for a
directory, `include` / `exclude` globs (relative, `/`-separated) pick the files.

`apply` backs up every file it would overwrite to ~/.dotfiles-backup/<time>/.
"""

import argparse
import difflib
import fnmatch
import json
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parent
MANIFEST = REPO / "dotfiles.json"
BACKUP_ROOT = Path.home() / ".dotfiles-backup"

PLATFORM = {"win32": "windows", "darwin": "macos"}.get(sys.platform, "linux")

# Scoop only sets $SCOOP when installed to a custom location.
os.environ.setdefault("SCOOP", str(Path.home() / "scoop"))


# --- manifest ---------------------------------------------------------------

def load_manifest():
    with open(MANIFEST, encoding="utf-8") as f:
        return json.load(f)


def save_manifest(manifest):
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")


def select(manifest, names):
    configs = manifest["configs"]
    if not names:
        return configs
    unknown = [n for n in names if n not in configs]
    if unknown:
        sys.exit(f"unknown config(s): {', '.join(unknown)} (known: {', '.join(configs)})")
    return {n: configs[n] for n in names}


def system_path(cfg):
    """The config's location on this platform, or None if it has none here."""
    raw = cfg["paths"].get(PLATFORM)
    if raw is None:
        return None
    expanded = os.path.expandvars(os.path.expanduser(raw))
    if "$" in expanded or "%" in expanded:
        sys.exit(f"can't expand {raw!r}: an environment variable is not set")
    return Path(expanded)


def portable(path):
    """Turn an absolute path back into the ~ / $VAR form used in the manifest."""
    path = Path(path).resolve()
    candidates = [("$" + v, os.environ.get(v)) for v in ("SCOOP", "APPDATA", "LOCALAPPDATA", "XDG_CONFIG_HOME")]
    candidates.append(("~", str(Path.home())))
    for name, value in candidates:
        if not value:
            continue
        try:
            rel = path.relative_to(Path(value).resolve())
        except ValueError:
            continue
        return name if str(rel) == "." else f"{name}/{rel.as_posix()}"
    return path.as_posix()


# --- file matching ----------------------------------------------------------

def matches(rel, patterns):
    return any(fnmatch.fnmatch(rel, p) for p in patterns)


def list_files(root, cfg):
    """Relative posix paths of the config's files under `root` (a dir)."""
    include = cfg.get("include", ["*"])
    exclude = cfg.get("exclude", [])
    found = set()
    if not root.is_dir():
        return found
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for fn in filenames:
            rel = (Path(dirpath) / fn).relative_to(root).as_posix()
            if matches(rel, include) and not matches(rel, exclude):
                found.add(rel)
    return found


def pairs(name, cfg):
    """Yield (rel, system_file, repo_file) for every file on either side.

    Returns None if the config has no path on this platform.
    """
    sys_path = system_path(cfg)
    if sys_path is None:
        return None
    repo_dir = REPO / name

    if cfg.get("file"):
        # Single-file config: stored in the repo under its own file name.
        rel = sys_path.name
        return [(rel, sys_path, repo_dir / rel)]

    rels = list_files(sys_path, cfg) | list_files(repo_dir, cfg)
    return [(rel, sys_path / rel, repo_dir / rel) for rel in sorted(rels)]


def same(a, b):
    return a.read_bytes() == b.read_bytes()


def file_state(sys_file, repo_file):
    if sys_file.exists() and repo_file.exists():
        return "same" if same(sys_file, repo_file) else "modified"
    if sys_file.exists():
        return "system only"
    if repo_file.exists():
        return "repo only"
    return "missing"


# --- commands ---------------------------------------------------------------

def cmd_status(args):
    for name, cfg in select(load_manifest(), args.names).items():
        files = pairs(name, cfg)
        if files is None:
            print(f"{name}: no path for {PLATFORM}, skipped")
            continue
        states = [(rel, file_state(s, r)) for rel, s, r in files]
        changed = [(rel, st) for rel, st in states if st != "same"]
        print(f"{name}: {'in sync' if not changed else f'{len(changed)} difference(s)'}"
              f"  ({system_path(cfg)})")
        for rel, st in changed:
            print(f"    {st:<12} {rel}")


def cmd_diff(args):
    for name, cfg in select(load_manifest(), args.names).items():
        for rel, sys_file, repo_file in pairs(name, cfg) or []:
            if file_state(sys_file, repo_file) == "same":
                continue

            def lines(p):
                if not p.exists():
                    return []
                try:
                    return p.read_text(encoding="utf-8").splitlines(keepends=True)
                except UnicodeDecodeError:
                    return ["<binary file>\n"]

            sys.stdout.writelines(difflib.unified_diff(
                lines(repo_file), lines(sys_file),
                f"repo/{name}/{rel}", f"system/{name}/{rel}"))


def copy(src, dst, dry_run):
    print(f"    {src} -> {dst}")
    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)


def cmd_save(args):
    """System -> repo."""
    for name, cfg in select(load_manifest(), args.names).items():
        files = pairs(name, cfg)
        if files is None:
            print(f"{name}: no path for {PLATFORM}, skipped")
            continue
        print(f"{name}:")
        if all(file_state(s, r) == "same" for _, s, r in files):
            print("    up to date")
        for rel, sys_file, repo_file in files:
            state = file_state(sys_file, repo_file)
            if state in ("modified", "system only"):
                copy(sys_file, repo_file, args.dry_run)
            elif state == "repo only":
                if args.prune:
                    print(f"    delete {repo_file}")
                    if not args.dry_run:
                        repo_file.unlink()
                else:
                    print(f"    (not on system, kept in repo; --prune to delete) {rel}")


def cmd_apply(args):
    """Repo -> system, backing up anything that gets overwritten."""
    backup_dir = BACKUP_ROOT / datetime.now().strftime("%Y%m%d-%H%M%S")
    backed_up = False
    for name, cfg in select(load_manifest(), args.names).items():
        files = pairs(name, cfg)
        if files is None:
            print(f"{name}: no path for {PLATFORM}, skipped")
            continue
        print(f"{name}:")
        if all(file_state(s, r) == "same" for _, s, r in files):
            print("    up to date")
        for rel, sys_file, repo_file in files:
            state = file_state(sys_file, repo_file)
            if state == "modified":
                backup = backup_dir / name / rel
                print(f"    backup {sys_file} -> {backup}")
                if not args.dry_run:
                    backup.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(sys_file, backup)
                    backed_up = True
            if state in ("modified", "repo only"):
                copy(repo_file, sys_file, args.dry_run)
    if backed_up:
        print(f"backups saved in {backup_dir}")


def cmd_add(args):
    manifest = load_manifest()
    path = Path(os.path.expandvars(os.path.expanduser(args.path))).resolve()
    if not path.exists():
        sys.exit(f"{path} does not exist")

    cfg = manifest["configs"].get(args.name, {"paths": {}})
    if args.name in manifest["configs"] and PLATFORM in cfg["paths"]:
        sys.exit(f"{args.name} already has a {PLATFORM} path: {cfg['paths'][PLATFORM]}")
    cfg["paths"][PLATFORM] = portable(path)
    if path.is_file():
        cfg["file"] = True
    else:
        if args.include:
            cfg["include"] = args.include
        if args.exclude:
            cfg["exclude"] = args.exclude
    manifest["configs"][args.name] = cfg
    save_manifest(manifest)
    print(f"added {args.name}: {cfg['paths'][PLATFORM]}")

    args.names = [args.name]
    cmd_save(args)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    for cmd, fn in (("status", cmd_status), ("diff", cmd_diff), ("save", cmd_save), ("apply", cmd_apply)):
        p = sub.add_parser(cmd)
        p.add_argument("names", nargs="*", help="configs to act on (default: all)")
        p.set_defaults(func=fn)
        if cmd in ("save", "apply"):
            p.add_argument("-n", "--dry-run", action="store_true", help="only print what would happen")
        if cmd == "save":
            p.add_argument("--prune", action="store_true", help="delete repo files no longer on the system")

    p = sub.add_parser("add")
    p.add_argument("name")
    p.add_argument("path", help="config file or directory on this machine")
    p.add_argument("-i", "--include", action="append", help="glob of files to track (repeatable; default: all)")
    p.add_argument("-x", "--exclude", action="append", help="glob of files to skip (repeatable)")
    p.add_argument("-n", "--dry-run", action="store_true")
    p.set_defaults(func=cmd_add, prune=False)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
