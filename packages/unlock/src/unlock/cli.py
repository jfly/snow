import argparse
import contextlib
import dataclasses
import subprocess
from typing import Self

import pexpect


@contextlib.contextmanager
def status(description: str):
    print(f"{description}... ", end="", flush=True)
    yield
    print("done!")


@dataclasses.dataclass
class MachineInfo:
    name: str
    hostname: str
    rootfs_password: str

    @classmethod
    def load(cls, machine: str, hostname: str | None) -> Self:
        with status(f"Loading info for {machine}"):
            if hostname is not None:
                tor_hostname_cp = None
            else:
                tor_hostname_cp = subprocess.Popen(
                    ["clan", "vars", "get", machine, "tor-hidden-service/hostname"],
                    text=True,
                    stdout=subprocess.PIPE,
                )

            rootfs_cp = subprocess.Popen(
                ["clan", "vars", "get", machine, "rootfs/password"],
                text=True,
                stdout=subprocess.PIPE,
            )
            assert rootfs_cp.stdout is not None

            if tor_hostname_cp is not None:
                assert tor_hostname_cp.wait() == 0, "failed to fetch tor hostname"
                assert tor_hostname_cp.stdout is not None
                hostname = tor_hostname_cp.stdout.read()
            assert rootfs_cp.wait() == 0, "failed to fetch rootfs password"

        assert hostname is not None
        return cls(
            name=machine,
            hostname=hostname,
            rootfs_password=rootfs_cp.stdout.read(),
        )


def unlock(machine: str, hostname: str | None):
    machine_info = MachineInfo.load(machine, hostname=hostname)

    with status(f"Connecting to {machine_info.hostname}"):
        args = [
            "ssh",
            "-t",
            f"root@{machine_info.hostname}",
            "TERM=dumb systemd-tty-ask-password-agent --query",
        ]
        if hostname is None:
            # If we were not given a hostname by the user, then we're connecting via tor.
            args = ["torsocks", *args]
        cmd, *args = args

        child = pexpect.spawn(cmd, args, encoding="utf8")
        child.expect(r"Enter key for [^:]+: \(press TAB for no echo\) ")

    with status("Sending passphrase"):
        child.sendline(machine_info.rootfs_password)
        child.wait()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("machine")
    parser.add_argument("hostname", nargs="?")
    args = parser.parse_args()
    unlock(args.machine, args.hostname)


if __name__ == "__main__":
    main()
