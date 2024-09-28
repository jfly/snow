import subprocess
import re
import logging

logger = logging.getLogger(__name__)


def _wpctl_id(name: str) -> int:
    cp = subprocess.run(
        ["wpctl", "inspect", name], text=True, capture_output=True, check=True
    )

    # Parse the id out of a line like this:
    #
    #   id 109, type PipeWire:Interface:Node
    #
    wpctl_re = re.compile(r"^id ([0-9]+).*$")
    first_line = cp.stdout.splitlines()[0]
    if m := wpctl_re.match(first_line):
        return int(m.group(1))
    else:
        assert False, f"Could not extract id from {first_line}"


class AlreadyLinkedError(Exception):
    pass


def _link(source_id: int, sink_id: int):
    cp = subprocess.run(
        ["pw-link", str(source_id), str(sink_id)], text=True, capture_output=True
    )
    if cp.returncode == 0:
        return
    elif cp.stderr == "failed to link ports: File exists\n":
        logger.warning(
            f"Source/sink appear to already be linked: {source_id}/{sink_id}"
        )
    else:
        cp.check_returncode()


def _unlink(source_id: int, sink_id: int):
    cp = subprocess.run(
        ["pw-link", "--disconnect", str(source_id), str(sink_id)],
        text=True,
        capture_output=True,
    )
    if cp.returncode == 0:
        return
    elif cp.stderr == "failed to unlink ports: No such file or directory\n":
        logger.warning(
            f"Source/sink appear to already be disconnected: {source_id}/{sink_id}"
        )
    else:
        cp.check_returncode()


def set_loopback(enable: bool):
    source_id = _wpctl_id("@DEFAULT_AUDIO_SOURCE@")
    sink_id = _wpctl_id("@DEFAULT_AUDIO_SINK@")

    if enable:
        _link(source_id, sink_id)
    else:
        _unlink(source_id, sink_id)
