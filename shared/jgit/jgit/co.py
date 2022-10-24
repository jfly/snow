import sys
import subprocess

from .gitlib import Cloneable


def co(remote: str, dry_run: bool):
    if dry_run:
        print("Beginning a dry run.", file=sys.stderr)
        print()

    clone(remote, dry_run=dry_run)

    if dry_run:
        print()
        print("Note: That was a dry run, nothing actually happened!", file=sys.stderr)


def clone(remote: str, dry_run: bool):
    cloneable = Cloneable(remote)
    destination = cloneable.destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        print(
            f"I found a folder {destination}, I'm going to optimistically assume it is a git repo set up for {cloneable.remote}",
            file=sys.stderr,
        )
        print(destination)
        return

    if not dry_run:
        subprocess.check_call(
            ["git", "clone", cloneable.remote],
            cwd=destination.parent,
            stdout=subprocess.DEVNULL,
        )
    print(destination)
