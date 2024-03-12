#!/usr/bin/env python

import sys
import argparse
import subprocess
from rich import print
from textwrap import dedent
from pathlib import Path


def root() -> Path:
    return Path(
        subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True
        ).strip()
    )


def encrypt(thing: str) -> str:
    p = subprocess.run(
        ["age", "-R", root() / "tools" / "age-public-key.pub", "--encrypt", "--armor"],
        input=thing,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return p.stdout


def main():
    parser = argparse.ArgumentParser(
        description=dedent(
            """\
            Encrypt some secret data

            Example:
                $ echo hunter2 | ./encrypt
            """
        )
    )
    parser.add_argument(
        "--strip-trailing-newline",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Whether or not to automatically remove trailing newlines if they exist.",
    )
    args = parser.parse_args()
    thing = sys.stdin.read()
    if thing[-1] == "\n" and args.strip_trailing_newline:
        print(
            dedent(
                """\
                    [red][bold]Courtesy alert[/bold]: I've detected that whatever
                    you're encrypting ends in a newline character and am removing it
                    for you. Use --no-strip-trailing-newline to disable this
                    behavior.[/red]
                """
            ),
            file=sys.stderr,
        )
        thing = thing[:-1]

    print(encrypt(thing), end="")


if __name__ == "__main__":
    main()
