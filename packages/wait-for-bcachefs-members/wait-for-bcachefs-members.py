# Helper script to wait for all members of a bcachefs filesystem to be present.
# This logic would ideally live in a bcachefs helper, or perhaps in systemd
# itself? See
# - <https://github.com/koverstreet/bcachefs/issues/930>
# - <https://github.com/systemd/systemd/issues/8234>
#
# Also note: this script is pretty brittle (it relies upon scraping the output of
# `bcachefs show-super`). See
# <https://github.com/koverstreet/bcachefs-tools/issues/188> for a discussion
# asking for a library or JSON output.

import subprocess
import argparse
import time
import dataclasses
import re
import sys
from pathlib import Path

# `bcachefs show-super` output looks like this (the line numbers are there for readability):
#
# 1|Device 5:     (not found)
# 2|  Label:      (none)
# 3|  UUID:       71acb50f-85bd-4430-b86c-9f75e85b84f9
# 4|Device 7:     /dev/loop2      /home/jeremy/tmp/bcachefsing/disk3
# 5|  Label:      disk3
# 6|  UUID:       bb762caf-9f75-4db3-9807-041f734d0b11
# 7|  Size:       1.00G
#
# Note how device 5 is not found, and the info lines are indented.
# It's not easy to see above, but frustratingly, some of these lines
# end in whitespace.

# Regex to match device lines (1, 4 above).
DEVICE_RE = re.compile(r"^Device (\d+): +(.+?) *$")

# Regex to match device info lines (2-3, 5-7 above).
DEVICE_INFO_RE = re.compile(r"^  (.+): +(.*?) *$")


@dataclasses.dataclass
class MemberStatus:
    number: int
    found: str | None
    label: str | None
    uuid: str

    def __str__(self) -> str:
        return f"<Member label={self.label} uuid={self.uuid}>"


@dataclasses.dataclass
class WipMemberStatus:
    number: int
    found: str | None
    info: dict[str, str]

    def add_info(self, key: str, value: str):
        self.info[key] = value

    def finalize(self) -> MemberStatus:
        label = self.info["Label"]
        if label == "(none)":
            label = None

        uuid = self.info["UUID"]

        return MemberStatus(
            number=self.number, found=self.found, label=label, uuid=uuid
        )


def get_member_statuses(device: Path) -> list[MemberStatus]:
    wip_member_statuses: list[WipMemberStatus] = []
    in_device = False

    cp = subprocess.run(
        ["bcachefs", "show-super", str(device)],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    )
    for line in cp.stdout.splitlines():
        if match := DEVICE_RE.fullmatch(line):
            in_device = True

            number = int(match.group(1))
            found = match.group(2)
            if found == "(not found)":
                found = None

            wip_member_statuses.append(
                WipMemberStatus(number=number, found=found, info={})
            )
        elif in_device and (match := DEVICE_INFO_RE.fullmatch(line)):
            key = match.group(1)
            value = match.group(2)
            wip_member_statuses[-1].add_info(key, value)
        else:
            in_device = False

    return [ms.finalize() for ms in wip_member_statuses]


def is_plural(count: int) -> bool:
    return count == 0 or count > 1


def count(count: int, noun: str) -> str:
    if count == 0 or count > 1:
        noun += "s"

    return f"{count} {noun}"


def is_or_are(count: int) -> str:
    return "are" if is_plural(count) else "is"


def ensure_bcachefs_module():
    module_path = Path("/sys/module/bcachefs")

    if module_path.exists():
        return

    subprocess.run(["modprobe", "bcachefs"], check=True)
    assert module_path.exists()


def wait_for_members(fs_uuid: str, key_location: Path | None):
    ensure_bcachefs_module()

    device = Path(f"/dev/disk/by-uuid/{fs_uuid}")

    while True:
        if device.exists():
            print(f"Found device: {device}", file=sys.stderr)
            break

        print(f"Waiting for {device}...", file=sys.stderr)
        time.sleep(5)

    if key_location is not None:
        subprocess.run(
            [
                "bcachefs",
                "unlock",
                device,
                # `--keyring session` is a workaround for <https://github.com/NixOS/nixpkgs/issues/32279>
                "--keyring",
                "session",
                "--file",
                key_location,
            ],
            check=True,
        )

    while True:
        member_statuses = get_member_statuses(device)
        missing_members = [
            member_status
            for member_status in member_statuses
            if member_status.found is None
        ]
        if len(missing_members) == 0:
            member_count = len(member_statuses)
            print(
                f"Success! All {count(member_count, 'member')} of {device} {is_or_are(member_count)} present.",
                file=sys.stderr,
            )
            break

        pretty_members = ",".join(map(str, missing_members))
        print(
            f"Waiting for {count(len(missing_members), 'missing member')} {pretty_members}...",
            file=sys.stderr,
        )
        time.sleep(5)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("fs_uuid")
    parser.add_argument(
        "--key-location",
        type=Path,
        help="Path to a file containing a passphrase to decrypt the device. Optional.",
    )
    args = parser.parse_args()

    wait_for_members(args.fs_uuid, args.key_location)


if __name__ == "__main__":
    main()
