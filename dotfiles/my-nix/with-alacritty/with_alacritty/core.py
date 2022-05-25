from functools import reduce
from mergedeep import merge
from typing import Callable
from typing import Optional
from typing import Literal
import xdg.BaseDirectory  # type: ignore
from pathlib import Path
from typing import Union
from typing import Any
import subprocess
import logging
import psutil
import json
import sys
import os
import re

logger = logging.getLogger(__name__)


def _config_dir() -> Path:
    p = xdg.BaseDirectory.save_config_path("with-alacritty")  # type: ignore
    return Path(p)


def _data_dir() -> Path:
    p = xdg.BaseDirectory.save_data_path("with-alacritty")  # type: ignore
    return Path(p)


def _terminal_conf_dir() -> Path:
    term_confs_dir = _data_dir().joinpath("termconfs")
    term_confs_dir.mkdir(exist_ok=True)
    return term_confs_dir


def _get_terminal_conf_path(pid: int) -> Path:
    return _terminal_conf_dir().joinpath(f"{pid}.alacritty.conf")


def _merged_conf_dir() -> Path:
    merged_confs_dir = _data_dir().joinpath("mergedconfs")
    merged_confs_dir.mkdir(exist_ok=True)
    return merged_confs_dir


def _get_merged_conf_path(pid: int) -> Path:
    return _merged_conf_dir().joinpath(f"{pid}.alacritty.conf")


def _get_global_conf_path() -> Path:
    default_conf_path = _data_dir().joinpath("global.conf")

    if not default_conf_path.exists():
        with default_conf_path.open("w") as f:
            json.dump({}, f)

    return default_conf_path


def _get_default_conf_path() -> Path:
    return _config_dir().joinpath("default.conf")


def _get_all_terminals() -> set[int]:
    """
    Returns the PIDs of all running terminals (or at least, the ones started by
    this wrapper).

    Also cleans up any config files that appear to no longer be in use.
    """
    pids = set()
    pid_conf_dirs = [_terminal_conf_dir(), _merged_conf_dir()]
    for d in pid_conf_dirs:
        for f in d.iterdir():
            pid_conf_re = re.compile(r"(\d+)\.alacritty\.conf")
            match = pid_conf_re.fullmatch(f.name)
            if not match:
                logger.warning(
                    "Ignoring unexpected file: %s. Expected it to match %s",
                    repr(str(f)),
                    pid_conf_re.pattern,
                )
                continue

            pid = int(match.group(1))
            pids.add(pid)

    # Check for any processes that are no longer running, and remove any
    # leftover config files for them.
    for pid in set(pids):
        if _is_alacritty_proccess(pid):
            continue

        pids.remove(pid)

        for d in pid_conf_dirs:
            f = d.joinpath(f"{pid}.alacritty.conf")
            if f.exists():
                try:
                    f.unlink()
                except FileNotFoundError:
                    # Oh well, someone else must have been doing the same thing
                    # at the exact same time as us.
                    continue
                else:
                    logger.info("Garbage collected old conf file: %s", repr(str(f)))

    return pids


def get_current_terminal_pid() -> Optional[int]:
    def ppid(process: psutil.Process) -> Optional[int]:
        parent = process.parent()
        if parent is None or parent.pid == process.pid:
            return None

        if _is_alacritty_proccess(parent.pid):
            return parent.pid

        return ppid(parent)

    return ppid(psutil.Process())


def _is_alacritty_proccess(pid: int):
    return _get_process_command(pid).startswith("alacritty ")


def _get_process_command(pid: int):
    return (
        subprocess.run(
            f"ps -p {pid} -o command",
            capture_output=True,
            shell=True,
        )
        .stdout.decode()
        .split("\n")[-2]
        .strip()
    )


Which = Union[Literal["default", "global", "current"], int]


class _Scope:
    _path: Path
    _affected_pids_getter: Callable[[], set[int]]
    _readonly: bool = False

    def __init__(self, which: Which):
        if which == "default":
            self._path = _get_default_conf_path()
            self._affected_pids_getter = _get_all_terminals
            self._readonly = True
        elif which == "global":
            self._path = _get_global_conf_path()
            self._affected_pids_getter = _get_all_terminals
        elif which == "current":
            pid = get_current_terminal_pid()
            assert pid is not None
            self._path = _get_terminal_conf_path(pid)
            self._affected_pids_getter = lambda: {pid}
        else:
            pid = int(which)
            self._path = _get_terminal_conf_path(pid)
            self._affected_pids_getter = lambda: {pid}

        logger.debug("_Scope: %s -> %s", which, self._path)

    def read(self) -> dict[str, Any]:
        with self._path.open("r") as f:
            return json.load(f)

    def write(self, value):
        # Write the updated settings to the conf file.
        with self._open("w") as f:
            json.dump(value, f)

        # Now regenerate all the affected configs.
        for pid in self.get_affected_pids():
            _generate_merged_config(pid)

    def _open(self, *args, **kwargs):
        assert not self._readonly
        return self._path.open(*args, **kwargs)

    def get_affected_pids(self):
        assert not self._readonly
        return self._affected_pids_getter()

    @property
    def path(self):
        return self._path


def _generate_merged_config(pid: int):
    def load_conf(path, ok_if_missing=False):
        if not path.exists() and ok_if_missing:
            return {}
        with path.open("r") as f:
            return json.load(f)

    configs = [
        load_conf(_get_default_conf_path(), ok_if_missing=True),
        load_conf(_get_global_conf_path()),
        load_conf(_get_terminal_conf_path(pid)),
    ]

    merged = reduce(merge, configs, {})
    merged[
        "live_config_reload"
    ] = True  # this whole thing relies upon this setting being enabled.

    merged_conf_path = _get_merged_conf_path(pid)
    with merged_conf_path.open("w") as f:
        json.dump(merged, f)

    return merged_conf_path


_DEL_VALUE = object()


def _update_json(current_json: dict[str, Any], json_path: str, new_value: Any):
    if "." == json_path:
        return {} if new_value is _DEL_VALUE else new_value

    # Make a copy of the incoming json, if possible. It's possible the incoming
    # json is not actually a dict, in which case we discard whatever value was
    # there and start with a fresh dictionary.
    if isinstance(current_json, dict):
        current_json = dict(current_json)
    else:
        current_json = {}

    if "." in json_path:
        key, remaining_path = json_path.split(".", maxsplit=1)
        current_json[key] = _update_json(
            current_json.get(key, {}), remaining_path, new_value
        )
    else:
        if new_value is _DEL_VALUE:
            del current_json[json_path]
        else:
            current_json[json_path] = new_value

    return current_json


def get(which: Which) -> dict[str, Any]:
    scope = _Scope(which)
    if not scope.path.exists():
        logging.error("File not found: %s", scope.path)
        sys.exit(1)

    return scope.read()


def update(which: Which, json_path: str, new_value: Any):
    scope = _Scope(which)
    current_settings = scope.read()

    new_settings = _update_json(current_settings, json_path, new_value)

    scope.write(new_settings)


def clear(which: Which, json_path: str):
    scope = _Scope(which)
    current_settings = scope.read()

    new_settings = _update_json(current_settings, json_path, _DEL_VALUE)

    scope.write(new_settings)


def start_new_terminal(args: list[str]):
    pid = os.getpid()

    # Start with an empty config file
    conf_path = _get_terminal_conf_path(pid)
    with conf_path.open("w") as f:
        json.dump({}, f)

    merged_path = _generate_merged_config(pid)

    # Rather than always invoking whatever alacritty happens to refer to on our
    # PATH, provide a mechanism for people to point us at some other binary.
    # This is useful if people want to set up a simple `alacritty` script that
    # invokes `with-alacritty alacritty`, so every single time they start
    # alacritty, they're actually starting a wrapped alacritty that can be
    # configured by with-alacritty.
    alacritty_bin = os.environ.get("ALACRITTY_TWEAKER_ALACRITTY_BIN", "alacritty")
    os.execvp(alacritty_bin, ["alacritty", "--config-file", str(merged_path), *args])
