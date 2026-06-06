#!/usr/bin/env python3
"""Collect unique media files using rdfind as the duplicate detector.

Default mode is a dry run. Use --apply to copy selected unique files into
photos/<year>/photos or photos/<year>/videos and move
duplicate losers to quarantine. Add --delete-losers with --apply only if you
want permanent deletion of newer duplicate copies.
"""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


MONTHS = {
    "jan": 1,
    "january": 1,
    "feb": 2,
    "february": 2,
    "mar": 3,
    "march": 3,
    "apr": 4,
    "april": 4,
    "may": 5,
    "jun": 6,
    "june": 6,
    "jul": 7,
    "july": 7,
    "aug": 8,
    "august": 8,
    "sep": 9,
    "sept": 9,
    "september": 9,
    "oct": 10,
    "october": 10,
    "nov": 11,
    "november": 11,
    "dec": 12,
    "december": 12,
}

YEAR_MONTH_DAY = re.compile(r"(?<!\d)((?:19|20)\d{2})[-_.](\d{1,2})[-_.](\d{1,2})(?!\d)")
COMPACT_YEAR_MONTH_DAY = re.compile(r"(?<!\d)((?:19|20)\d{2})(\d{2})(\d{2})(?!\d)")
DAY_MONTH_YEAR = re.compile(
    r"(?i)(?<![a-z0-9])(\d{1,2})[-_ .]"
    r"(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|"
    r"jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"
    r"[-_ .](\d{2,4})(?![a-z0-9])"
)
YEAR_MONTH_NAME_DAY = re.compile(
    r"(?i)(?<![a-z0-9])((?:19|20)\d{2})[-_ .]"
    r"(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|jun(?:e)?|"
    r"jul(?:y)?|aug(?:ust)?|sep(?:t|tember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"
    r"[-_ .](\d{1,2})(?![a-z0-9])"
)

PHOTO_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".heic",
    ".heif",
    ".gif",
    ".webp",
    ".tif",
    ".tiff",
    ".bmp",
    ".dng",
    ".raw",
    ".arw",
    ".cr2",
    ".nef",
}

VIDEO_EXTENSIONS = {
    ".mp4",
    ".mov",
    ".m4v",
    ".3gp",
    ".avi",
    ".mkv",
    ".mts",
    ".m2ts",
    ".webm",
}


def parse_args() -> argparse.Namespace:
    examples = """
examples:
  ./dedupe-photos.py --reuse-results
      Dry-run using the existing duplicates.txt.

  ./dedupe-photos.py
      Dry-run and rerun rdfind.

  ./dedupe-photos.py --rdfind /path/to/rdfind
      Dry-run with an explicit rdfind path if PATH does not include rdfind.

  ./dedupe-photos.py --apply
      Copy unique files into grouped year folders and quarantine duplicate losers.

  ./dedupe-photos.py --apply --delete-losers
      Copy unique files and permanently delete duplicate losers after hash verification.

output layout:
  photos/<year>/photos/
  photos/<year>/videos/
  photos/<year>/other/
"""
    parser = argparse.ArgumentParser(
        description="Use rdfind to detect duplicates, keep the oldest copy, and collect unique media files.",
        epilog=examples,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--base", type=Path, default=Path.cwd(), help="base dir (default: current directory)")
    parser.add_argument("--dest", type=Path, default=Path("photos"), help="dest dir (default: %(default)s)")
    parser.add_argument("--results", type=Path, default=Path("duplicates.txt"), help="rdfind report (default: %(default)s)")
    parser.add_argument("--plan", type=Path, default=Path("dedupe-plan.jsonl"), help="plan file (default: %(default)s)")
    parser.add_argument("--rdfind", default=None, help="path to rdfind; defaults to PATH")
    parser.add_argument("--reuse-results", action="store_true", help="parse existing results instead of running rdfind")
    parser.add_argument("--apply", action="store_true", help="actually copy selected files and move/delete duplicate losers")
    parser.add_argument(
        "--delete-losers",
        action="store_true",
        help="with --apply, permanently delete duplicate losers instead of moving them to quarantine",
    )
    parser.add_argument(
        "--source",
        action="append",
        type=Path,
        help="source path relative to --base or absolute; repeatable. Defaults to non-hidden files/dirs in --base except dest/quarantine/report/plan/script.",
    )
    return parser.parse_args()


def resolve_rdfind(user_path: Optional[str]) -> Optional[str]:
    if user_path:
        path = Path(user_path).expanduser()
        if path.is_file() and os.access(path, os.X_OK):
            return str(path)
        return None
    return shutil.which("rdfind")


def is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def resolve_under_base(base: Path, value: Path) -> Path:
    value = value.expanduser()
    return (value if value.is_absolute() else base / value).resolve()


def safe_relative(path: Path, base: Path) -> Path:
    try:
        return path.relative_to(base)
    except ValueError:
        digest = hashlib.sha1(str(path).encode("utf-8", errors="surrogateescape")).hexdigest()[:12]
        return Path("external-sources") / digest / path.name


def source_contains(path: Path, source: Path) -> bool:
    if source.is_file():
        return path == source
    return path == source or is_relative_to(path, source)


def default_sources(base: Path, dest: Path, excluded_files: Sequence[Path]) -> List[Path]:
    sources = []
    excluded = {path.resolve() for path in excluded_files}
    for child in sorted(base.iterdir()):
        if child.name.startswith("."):
            continue
        child = child.resolve()
        if child in excluded:
            continue
        if child.is_symlink():
            continue
        if child == dest.resolve() or is_relative_to(child, dest.resolve()):
            continue
        if child.name == ".dedupe-quarantine":
            continue
        if not (child.is_file() or child.is_dir()):
            continue
        sources.append(child)
    return sources


def normalize_sources(
    base: Path,
    raw_sources: Optional[Sequence[Path]],
    dest: Path,
    excluded_files: Sequence[Path],
) -> List[Path]:
    if not raw_sources:
        return default_sources(base, dest, excluded_files)

    sources = []
    for source in raw_sources:
        path = resolve_under_base(base, source)
        if not path.exists():
            raise SystemExit(f"Source path not found: {path}")
        if path.is_symlink() or not (path.is_file() or path.is_dir()):
            raise SystemExit(f"Source path is not a regular file or directory: {path}")
        dest = dest.resolve()
        if path == dest or is_relative_to(path, dest) or (path.is_dir() and is_relative_to(dest, path)):
            raise SystemExit(f"Refusing to scan destination path as a source: {path}")
        sources.append(path)
    return sources


def run_rdfind(rdfind: str, sources: Sequence[Path], results: Path) -> None:
    cmd = [
        rdfind,
        "-deterministic",
        "true",
        "-makeresultsfile",
        "true",
        "-outputname",
        str(results),
    ] + [str(source) for source in sources]
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)


def parse_rdfind_results(results: Path, sources: Sequence[Path]) -> Dict[int, List[Path]]:
    groups: Dict[int, List[Path]] = {}
    source_paths = [source.resolve() for source in sources]

    with results.open("r", encoding="utf-8", errors="replace") as handle:
        for line_number, line in enumerate(handle, 1):
            stripped = line.rstrip("\n")
            if not stripped or stripped.startswith("#"):
                continue
            fields = stripped.split(maxsplit=7)
            if len(fields) != 8 or not fields[0].startswith("DUPTYPE_"):
                print(f"Skipping unrecognized rdfind row {line_number}: {stripped}", file=sys.stderr)
                continue
            try:
                group_id = abs(int(fields[1]))
            except ValueError:
                print(f"Skipping rdfind row with invalid id {line_number}: {stripped}", file=sys.stderr)
                continue

            path = Path(fields[7]).expanduser()
            if not path.is_absolute():
                path = (results.parent / path).resolve()
            else:
                path = path.resolve()

            if not path.exists():
                print(f"Skipping missing rdfind path: {path}", file=sys.stderr)
                continue
            if path.is_symlink() or not path.is_file():
                print(f"Skipping non-regular rdfind path: {path}", file=sys.stderr)
                continue
            if not any(source_contains(path, source) for source in source_paths):
                continue
            groups.setdefault(group_id, []).append(path)

    return {group_id: paths for group_id, paths in groups.items() if len(paths) > 1}


def all_source_files(sources: Sequence[Path]) -> List[Path]:
    files = []
    for source in sources:
        if source.is_file():
            if not source.is_symlink():
                files.append(source.resolve())
            continue
        for path in source.rglob("*"):
            if path.is_symlink() or not path.is_file():
                continue
            files.append(path.resolve())
    return sorted(files)


def safe_datetime(year: int, month: int, day: int) -> Optional[dt.datetime]:
    try:
        return dt.datetime(year, month, day)
    except ValueError:
        return None


def two_digit_year(value: int) -> int:
    return 2000 + value if value < 70 else 1900 + value


def parse_date_from_text(text: str) -> Optional[dt.datetime]:
    for match in YEAR_MONTH_DAY.finditer(text):
        parsed = safe_datetime(int(match.group(1)), int(match.group(2)), int(match.group(3)))
        if parsed:
            return parsed

    for match in COMPACT_YEAR_MONTH_DAY.finditer(text):
        parsed = safe_datetime(int(match.group(1)), int(match.group(2)), int(match.group(3)))
        if parsed:
            return parsed

    for match in DAY_MONTH_YEAR.finditer(text):
        year_raw = int(match.group(3))
        year = two_digit_year(year_raw) if year_raw < 100 else year_raw
        parsed = safe_datetime(year, MONTHS[match.group(2).lower()], int(match.group(1)))
        if parsed:
            return parsed

    for match in YEAR_MONTH_NAME_DAY.finditer(text):
        parsed = safe_datetime(int(match.group(1)), MONTHS[match.group(2).lower()], int(match.group(3)))
        if parsed:
            return parsed

    return None


def chosen_timestamp(path: Path, base: Path) -> Tuple[float, str]:
    basename_date = parse_date_from_text(path.name)
    if basename_date:
        return basename_date.timestamp(), "filename-date"

    try:
        relative_text = str(path.relative_to(base))
    except ValueError:
        relative_text = str(path)
    path_date = parse_date_from_text(relative_text)
    if path_date:
        return path_date.timestamp(), "path-date"

    return path.stat().st_mtime, "metadata-mtime"


def choose_keeper(paths: Sequence[Path], base: Path) -> Tuple[Path, str]:
    ranked = []
    for path in paths:
        timestamp, reason = chosen_timestamp(path, base)
        ranked.append((timestamp, str(safe_relative(path, base)), reason, path))
    ranked.sort(key=lambda item: (item[0], item[1]))
    return ranked[0][3], ranked[0][2]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collision_safe_path(path: Path, reserved: Optional[set] = None) -> Path:
    reserved = reserved or set()
    if not path.exists() and path not in reserved:
        return path
    stem = path.stem
    suffix = path.suffix
    parent = path.parent
    for index in range(1, 10000):
        candidate = parent / f"{stem}__copy{index}{suffix}"
        if not candidate.exists() and candidate not in reserved:
            return candidate
    raise RuntimeError(f"Could not find collision-free path for {path}")


def media_bucket(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in PHOTO_EXTENSIONS:
        return "photos"
    if suffix in VIDEO_EXTENSIONS:
        return "videos"
    return "other"


def planned_dest_for(source: Path, base: Path, dest: Path) -> Path:
    timestamp, _ = chosen_timestamp(source, base)
    year = dt.datetime.fromtimestamp(timestamp).strftime("%Y")
    return dest / year / media_bucket(source) / source.name


def write_plan(plan_path: Path, actions: Iterable[dict]) -> None:
    with plan_path.open("w", encoding="utf-8") as handle:
        for action in actions:
            handle.write(json.dumps(action, sort_keys=True) + "\n")


def progress(message: str) -> None:
    print(message, flush=True)


def copy_selected_files(selected: Sequence[Path], base: Path, dest: Path, apply: bool) -> List[dict]:
    actions = []
    planned_targets = set()
    total = len(selected)
    if total:
        progress(f"Preparing to {'copy' if apply else 'plan'} {total} selected unique files...")
    for index, source in enumerate(selected, 1):
        progress(f"[copy {index}/{total}] checking {source}")
        natural_target = planned_dest_for(source, base, dest)
        target = natural_target
        timestamp, reason = chosen_timestamp(source, base)
        action = {
            "action": "copy-selected",
            "bucket": media_bucket(source),
            "date_reason": reason,
            "source": str(source),
            "target": str(target),
            "year": dt.datetime.fromtimestamp(timestamp).strftime("%Y"),
        }
        if natural_target.exists() and sha256(source) == sha256(natural_target):
            target = natural_target
            action["status"] = "already-present"
        elif natural_target in planned_targets:
            target = collision_safe_path(natural_target, planned_targets)
            action["target"] = str(target)
            if apply:
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
                action["status"] = "copied"
            else:
                action["status"] = "dry-run"
        elif apply:
            target = collision_safe_path(natural_target, planned_targets)
            action["target"] = str(target)
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            action["status"] = "copied"
        else:
            target = collision_safe_path(natural_target, planned_targets)
            action["target"] = str(target)
            action["status"] = "dry-run"
        planned_targets.add(target)
        progress(f"[copy {index}/{total}] {action['status']} -> {target}")
        actions.append(action)
    return actions


def handle_losers(
    duplicate_groups: Dict[int, List[Path]],
    keepers: Dict[int, Path],
    base: Path,
    quarantine: Path,
    apply: bool,
    delete_losers: bool,
) -> List[dict]:
    actions = []
    loser_items = []
    for group_id, paths in sorted(duplicate_groups.items()):
        keeper = keepers[group_id]
        for loser in sorted(path for path in paths if path != keeper):
            loser_items.append((group_id, keeper, loser))

    total = len(loser_items)
    if total:
        loser_action = "delete" if apply and delete_losers else "quarantine" if apply else "plan"
        progress(f"Preparing to {loser_action} {total} duplicate loser files...")

    for index, (group_id, keeper, loser) in enumerate(loser_items, 1):
        progress(f"[duplicate {index}/{total}] verifying {loser}")
        keeper_hash = sha256(keeper)
        action = {
            "action": "delete-duplicate" if delete_losers else "quarantine-duplicate",
            "group": group_id,
            "keeper": str(keeper),
            "loser": str(loser),
        }
        loser_hash = sha256(loser)
        if loser_hash != keeper_hash:
            action["status"] = "skipped-hash-mismatch"
            progress(f"[duplicate {index}/{total}] skipped hash mismatch")
            actions.append(action)
            continue

        if apply and delete_losers:
            loser.unlink()
            action["status"] = "deleted"
        elif apply:
            target = collision_safe_path(quarantine / safe_relative(loser, base))
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(loser), str(target))
            action["target"] = str(target)
            action["status"] = "quarantined"
        else:
            action["status"] = "dry-run"
        progress(f"[duplicate {index}/{total}] {action['status']}")
        actions.append(action)
    return actions


def main() -> int:
    args = parse_args()
    base = args.base.expanduser().resolve()
    dest = resolve_under_base(base, args.dest)
    results = resolve_under_base(base, args.results)
    plan_path = resolve_under_base(base, args.plan)
    quarantine = base / ".dedupe-quarantine" / dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    excluded_files = [results, plan_path, Path(__file__).resolve()]

    if not base.is_dir():
        raise SystemExit(f"Base directory not found: {base}")
    if args.apply:
        dest.mkdir(parents=True, exist_ok=True)
    sources = normalize_sources(base, args.source, dest, excluded_files)
    if not sources:
        raise SystemExit("No source paths found")

    print(f"Base: {base}")
    print(f"Destination: {dest}")
    print("Sources:")
    for source in sources:
        print(f"  {source}")

    if args.reuse_results:
        if not results.is_file():
            raise SystemExit(f"Cannot reuse missing rdfind results file: {results}")
        print(f"Reusing rdfind results: {results}")
    else:
        rdfind = resolve_rdfind(args.rdfind)
        if not rdfind:
            raise SystemExit(
                "rdfind was not found on PATH. Install rdfind, pass --rdfind /path/to/rdfind, "
                "or rerun with --reuse-results to parse the existing duplicates.txt."
            )
        run_rdfind(rdfind, sources, results)

    duplicate_groups = parse_rdfind_results(results, sources)
    keepers: Dict[int, Path] = {}
    loser_paths = set()
    group_actions = []
    for group_id, paths in sorted(duplicate_groups.items()):
        keeper, reason = choose_keeper(paths, base)
        keepers[group_id] = keeper
        losers = sorted(path for path in paths if path != keeper)
        loser_paths.update(losers)
        group_actions.append(
            {
                "action": "choose-keeper",
                "group": group_id,
                "keeper": str(keeper),
                "reason": reason,
                "duplicates": [str(path) for path in sorted(paths)],
                "losers": [str(path) for path in losers],
            }
        )

    source_files = all_source_files(sources)
    selected = [path for path in source_files if path not in loser_paths]

    actions = []
    actions.extend(group_actions)
    actions.extend(copy_selected_files(selected, base, dest, args.apply))
    actions.extend(handle_losers(duplicate_groups, keepers, base, quarantine, args.apply, args.delete_losers))
    write_plan(plan_path, actions)

    print()
    print(f"Duplicate groups: {len(duplicate_groups)}")
    print(f"Duplicate losers: {len(loser_paths)}")
    print(f"Selected unique files to collect: {len(selected)}")
    print(f"Plan written to: {plan_path}")

    if args.apply:
        print("Applied plan.")
        if args.delete_losers:
            print("Duplicate losers were permanently deleted after hash verification.")
        else:
            print(f"Duplicate losers were moved to quarantine: {quarantine}")
    else:
        print("Dry run only. No files were copied, moved, or deleted.")
        print("Run with --apply to copy selected files and quarantine duplicate losers.")
        print("Run with --apply --delete-losers only if you want permanent deletion.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
