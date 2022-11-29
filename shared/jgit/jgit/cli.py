import sys
import argparse
import pathlib
import textwrap

from .org_repos import organize
from .co import co


# Subclass ArgumentParser to get help to print to stderr. This is nice because
# callers expect this script to only print a path to stdout (see the `co`
# shell function that calls this script).
class StderrParser(argparse.ArgumentParser):
    def print_help(self, *args, **kwargs):
        super().print_help(*args, **kwargs, file=sys.stderr)


def main():
    parser = StderrParser()
    subparsers = parser.add_subparsers(required=True)

    subparser = subparsers.add_parser(
        "co",
        help="clone git remote",
        description=textwrap.dedent(
            """\
            "clone-ish": clones the given url into a deterministic path in ~/src
            and prints that path. If that path already exists, just prints the
            path.
            """
        ),
    )
    subparser.add_argument("remote")
    subparser.add_argument(
        "--force-https",
        action="store_true",
        help="force use of https url, rather than converting it to a git ssh url. useful when cloning a from a random gitlab instance that you haven't created an account with yet",
    )
    subparser.add_argument(
        "--dry-run",
        action="store_true",
        help="do nothing, just print what would happen",
    )
    subparser.set_defaults(func=do_co)

    subparser = subparsers.add_parser(
        "org",
        help="organize a given directory of git repos",
        description=textwrap.dedent(
            """\
            Given a directory of git repos, reorganize them all under ~/src
            according to the same rules as the `co` subcommand.
            """
        ),
    )
    subparser.add_argument(
        "organize_me",
        help="Directory of git repos to organize",
        type=pathlib.Path,
    )
    subparser.add_argument(
        "--dry-run",
        action="store_true",
        help="do nothing, just print what would happen",
    )
    subparser.set_defaults(func=do_org)

    args = parser.parse_args()
    args.func(args)


def do_co(args):
    co(
        remote=args.remote,
        force_https=args.force_https,
        dry_run=args.dry_run,
    )


def do_org(args):
    organize(
        path=args.organize_me,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()
