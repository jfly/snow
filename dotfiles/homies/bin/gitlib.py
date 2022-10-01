import re
from pathlib import Path
import configparser

__all__ = ['parse_remote']

def parse_remote(remote: str):
    regexps = [
        re.compile(r"^git@(?P<service>[^/]+):(?P<org>.+)/(?P<repo>[^/]+).git$"),
        re.compile(r"^https://(?P<service>[^/]+)/(?P<org>[^/]+)/(?P<repo>[^/]+?)(?:.git)?$"),
        re.compile(r"^ssh://(?P<service>clark)/state/git/(?P<repo>[^/]+?)(?:.git)?$"),
    ]

    for regexp in regexps:
        if match := regexp.match(remote):
            return match.groups()

    return None

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
