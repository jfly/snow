import re
from pathlib import Path
import configparser


class NotCloneableException(Exception):
    pass


def compile_all(*res: str):
    return [re.compile(r, re.VERBOSE) for r in res]


REMOTE_REGEXPS = compile_all(
    ## First, domain specific rules
    # clark
    r"^(?P<protocol>ssh://)    (?P<domain>clark)             /state/git/  (?P<path>.+?)$",
    # github
    r"^(?P<protocol>https://)  (?P<domain>github.com)        /            (?P<path>[^/]+/[^/]+)  (/.*)?$",
    ## And now, generic rules
    r"^(?P<protocol>ssh://)    (?:[^@]+@)?(?P<domain>[^/]+)  /            (?P<path>.+?)$",
    r"^(?P<protocol>git@)      (?P<domain>[^/]+)             :            (?P<path>.+?)$",
    r"^(?P<protocol>https://)  (?P<domain>[^/]+)             /            (?P<path>.+?)$",
)


class Cloneable:
    def __init__(self, remote: str, force_https=False):
        match = self._find_match(remote)
        groups = match.groupdict()
        protocol = groups.pop("protocol")
        groups["path"] = groups["path"].removesuffix(".git")
        self._pieces = [
            piece for group in groups.values() for piece in group.split("/")
        ]

        self._remote = (
            f"git@{groups['domain']}:{groups['path']}.git"
            if protocol == "https://" and not force_https
            else remote
        )

    def _find_match(self, remote: str):
        for regexp in REMOTE_REGEXPS:
            if match := regexp.match(remote):
                return match

        raise NotCloneableException(remote)

    @property
    def destination(self) -> Path:
        assert self._pieces is not None
        return (Path.home() / "src").joinpath(*self._pieces)

    @property
    def remote(self) -> str:
        return self._remote


class InvalidGitRepo(Exception):
    pass


def parse_gitconfig(git_dir: Path) -> configparser.ConfigParser:
    git_config = git_dir.joinpath(".git", "config")
    if not git_config.is_file():
        raise InvalidGitRepo(f"Couldn't find {git_config}")

    config = configparser.ConfigParser()
    with git_config.open() as f:
        config.read_string(f.read())

    return config
