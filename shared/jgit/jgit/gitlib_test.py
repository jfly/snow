import os
import pytest
from pathlib import Path

from .gitlib import Cloneable
from .gitlib import NotCloneableException


def collapseuser(path: Path):
    return str(path).replace(os.path.expanduser("~"), "~")


def assert_parse(remote: str, clone_from: str, clone_to: str):
    cloneable = Cloneable(remote)
    assert collapseuser(cloneable.destination) == clone_to
    assert cloneable.remote == clone_from


def test_github():
    assert_parse(
        remote="https://github.com/jfly/snow",
        clone_from="git@github.com:jfly/snow.git",
        clone_to="~/src/github.com/jfly/snow",
    )
    assert_parse(
        remote="https://github.com/jfly/snow.git",
        clone_from="git@github.com:jfly/snow.git",
        clone_to="~/src/github.com/jfly/snow",
    )

    # Try some urls straight from browsing github repos
    assert_parse(
        remote="https://github.com/jfly/snow/tree/main/fflewddur",
        clone_from="git@github.com:jfly/snow.git",
        clone_to="~/src/github.com/jfly/snow",
    )
    assert_parse(
        remote="https://github.com/jfly/snow/blob/e25435b7534374b2698c753dffc540b668ae1585/fflewddur/configuration.nix",
        clone_from="git@github.com:jfly/snow.git",
        clone_to="~/src/github.com/jfly/snow",
    )
    assert_parse(
        remote="https://github.com/jfly/snow/pulls",
        clone_from="git@github.com:jfly/snow.git",
        clone_to="~/src/github.com/jfly/snow",
    )


def test_ssh():
    assert_parse(
        remote="ssh://user@server/path/to/test-repo.git",
        clone_from="ssh://user@server/path/to/test-repo.git",
        clone_to="~/src/server/path/to/test-repo",
    )

    # Verify special handling of clark (strip the `/state/git`)
    assert_parse(
        remote="ssh://clark/state/git/test-repo.git",
        clone_from="ssh://clark/state/git/test-repo.git",
        clone_to="~/src/clark/test-repo",
    )


def test_gitlab():
    assert_parse(
        remote="git@gitlab.freedesktop.org:pipewire/wireplumber.git",
        clone_from="git@gitlab.freedesktop.org:pipewire/wireplumber.git",
        clone_to="~/src/gitlab.freedesktop.org/pipewire/wireplumber",
    )
    assert_parse(
        remote="https://gitlab.freedesktop.org/pipewire/wireplumber.git",
        clone_from="git@gitlab.freedesktop.org:pipewire/wireplumber.git",
        clone_to="~/src/gitlab.freedesktop.org/pipewire/wireplumber",
    )


def test_invalid_remote():
    with pytest.raises(NotCloneableException):
        Cloneable(remote="totally bogus string")
