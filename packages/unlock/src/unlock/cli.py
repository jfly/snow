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
    hostname: str
    tor_hostname: str
    rootfs_password: str

    @classmethod
    def load(cls, hostname: str) -> Self:
        with status(f"Loading hostname and rootfs password for {hostname}"):
            tor_hostname_cp = subprocess.Popen(
                ["clan", "vars", "get", hostname, "tor-hidden-service/hostname"],
                text=True,
                stdout=subprocess.PIPE,
            )
            assert tor_hostname_cp.stdout is not None

            rootfs_cp = subprocess.Popen(
                ["clan", "vars", "get", hostname, "rootfs/password"],
                text=True,
                stdout=subprocess.PIPE,
            )
            assert rootfs_cp.stdout is not None

            assert tor_hostname_cp.wait() == 0, "failed to fetch tor hostname"
            assert rootfs_cp.wait() == 0, "failed to fetch rootfs password"

        return cls(
            hostname=hostname,
            tor_hostname=tor_hostname_cp.stdout.read(),
            rootfs_password=rootfs_cp.stdout.read(),
        )


def unlock(machine: str):
    machine_info = MachineInfo.load(machine)

    with status(f"Connecting to {machine_info.tor_hostname}"):
        child = pexpect.spawn(
            "torsocks",
            [
                "ssh",
                "-t",
                f"root@{machine_info.tor_hostname}",
                "TERM=dumb systemd-tty-ask-password-agent --query",
            ],
            encoding="utf8",
        )
        child.expect(r"Enter key for [^:]+: \(press TAB for no echo\) ")

    with status("Sending passphrase"):
        child.sendline(machine_info.rootfs_password)
        child.wait()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("machine")
    args = parser.parse_args()
    unlock(args.machine)


if __name__ == "__main__":
    main()
