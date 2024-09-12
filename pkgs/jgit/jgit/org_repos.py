from .gitlib import parse_gitconfig
from .gitlib import InvalidGitRepo
from .gitlib import Cloneable
import sys
import configparser
from pathlib import Path


def organize(path: Path, dry_run: bool):
    if dry_run:
        print("Beginning a dry run.", file=sys.stderr)
        print()

    for p in path.iterdir():
        analyze(p, dry_run=dry_run)

    if dry_run:
        print()
        print("Note: That was a dry run, nothing actually happened!", file=sys.stderr)


def find_remote(git_config: configparser.ConfigParser):
    remotes = [
        "upstream",
        "origin",
    ]
    for remote in remotes:
        section = f'remote "{remote}"'
        if section in git_config:
            return git_config[section]

    return None


def analyze(p: Path, dry_run: bool):
    if not p.is_dir():
        print(f"Skipping {p}: non-directory", file=sys.stderr)
        return

    success, msg = try_git(p, dry_run)
    msg = f"{try_git.__name__}: {msg}"
    if success:
        print(msg, file=sys.stderr)
    else:
        print(f"Couldn't figure out what to do with {p}. Errors:", file=sys.stderr)
        print(f"\t{msg}")


def try_git(p: Path, dry_run: bool):
    try:
        config = parse_gitconfig(p)
    except InvalidGitRepo as e:
        return False, f"Skipping {p}: {str(e)}"

    remote_section = find_remote(config)
    if remote_section is None:
        return False, f"Skipping {p}: git config has no recognized remotes"

    cloneable = Cloneable(remote_section["url"])
    destination = cloneable.destination
    if not dry_run:
        destination.parent.mkdir(parents=True, exist_ok=True)
        p.rename(destination)

    return True, f"Renamed {p} -> {destination}"
