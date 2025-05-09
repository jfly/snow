import argparse
import sys
import os
from pathlib import Path

VM_OVMF_FIRMWARE = os.environ["VM_OVMF_FIRMWARE"]
VM_OVMF_VARIABLES = os.environ["VM_OVMF_VARIABLES"]


def find_disks(vm_dir: Path) -> list[Path]:
    disks = list(vm_dir.glob("disk*.qcow2"))
    if len(disks) == 0:
        print("Could not find any VM disks.", file=sys.stderr)
        print("Create one with a command like this:", file=sys.stderr)
        print(f"    qemu-img create -f qcow2 {vm_dir}/disk1.qcow2 20G", file=sys.stderr)
        print(
            "If you want multiple drives, name them disk2.qcow2, disk3.qcow2, etc.",
            file=sys.stderr,
        )
        sys.exit(1)

    return disks


def start_vm(vm_dir: Path, iso: Path | None):
    disks = sorted(find_disks(vm_dir))

    drive_argss: list[tuple[str, str]] = []

    def add_drive(file: Path, _if: str, media: str):
        index = len(drive_argss)
        drive_argss.append(
            ("-drive", f"file={file},if={_if},media={media},index={index}")
        )

    for disk in disks:
        add_drive(file=disk, _if="ide", media="disk")

    if iso is not None:
        add_drive(file=iso, _if="ide", media="cdrom")

    os.chdir(vm_dir)
    os.execvp(
        "qemu-kvm",
        [
            "qemu-kvm",
            "-m",
            "4096",
            "-device",
            "e1000,netdev=net0",
            "-netdev",
            "user,id=net0,hostfwd=tcp::5555-:22",
            "-drive",
            f"if=pflash,format=raw,unit=0,readonly=on,file={VM_OVMF_FIRMWARE}",
            "-drive",
            f"if=pflash,format=raw,unit=1,readonly=on,file={VM_OVMF_VARIABLES}",
            *[arg for drive_args in drive_argss for arg in drive_args],
        ],
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("vm_name")
    parser.add_argument("--iso")

    args = parser.parse_args()
    assert isinstance(args.vm_name, str)

    XDG_STATE_HOME = Path(
        os.environ.get("XDG_STATE_HOME", os.path.expandvars("$HOME/.local/state"))
    )
    state_dir = XDG_STATE_HOME / "vms"
    vm_dir = state_dir / args.vm_name

    vm_dir.parent.mkdir(parents=True, exist_ok=True)

    start_vm(vm_dir, args.iso)


if __name__ == "__main__":
    main()
