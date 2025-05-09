#!/usr/bin/env python

import shlex
import os
from typing import Literal
import click
import shutil
import tempfile
import subprocess
from pathlib import Path
from textwrap import dedent

MACHINES_DIR = Path("machines")

HOSTS_DIR = Path("hosts")
HELP = (HOSTS_DIR / "README.md").read_text()


@click.group(help=HELP)
def main():
    pass


@main.command()
@click.option(
    "--force/--no-force",
    default=False,
    help="Overwrite existing host directory, if one exists",
)
@click.argument("hostname")
def declare(hostname: str, force: bool):
    machine_dir = MACHINES_DIR / hostname
    if machine_dir.exists():
        if force:
            shutil.rmtree(machine_dir)
        else:
            raise click.ClickException(
                f"{machine_dir} already exists. Use --force to overwrite."
            )

    template_host_dir = MACHINES_DIR / "template"

    shutil.copytree(template_host_dir, machine_dir)

    click.echo(
        dedent(
            f"""
            Successfully generated {machine_dir}. Next steps:

              - Try it out in a VM: `tools/fleet.py vm {hostname}`
              - Bootstrap a real machine: `tools/fleet.py bootstrap {hostname}`
            """
        )
    )


@main.command()
@click.argument("hostname")
def vm(hostname: str):
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)

        result_dir = tmpdir / "result"

        subprocess.run(
            [
                "nix",
                "build",
                f".#nixosConfigurations.{hostname}.config.system.build.vmWithBootLoader",
                "--out-link",
                result_dir,
            ],
            check=True,
        )

        subprocess.run(
            [result_dir / f"bin/run-{hostname}-vm"],
            check=True,
            # Run in the tempdir because qemu creates a couple of files
            # (*-efi-vars.fd and *.qcow2) that I don't want littering the repo.
            # I haven't been able to figure out how to prevent creating those.
            cwd=tmpdir,
        )


def ssh_and_run(ssh: str, ssh_port: int, command: str):
    subprocess.run(
        [
            "ssh",
            ssh,
            "-p",
            str(ssh_port),
            "-t",  # Allocate TTY in case var generation prompts us for input.
            command,
        ],
        check=True,
    )


def generate_vars(ssh: str, ssh_port: int, hostname: str):
    print(f"Generating vars for {hostname}")
    generate_script = (
        subprocess.run(
            [
                "nix",
                "build",
                f".#nixosConfigurations.{hostname}.config.system.build.generate-vars",
                "--no-link",
                "--print-out-paths",
            ],
            check=True,
            stdout=subprocess.PIPE,
            text=True,
        ).stdout.strip()
        + "/bin/generate-vars"
    )
    subprocess.run(
        [
            "nix",
            "copy",
            generate_script,
            "--to",
            f"ssh-ng://{ssh}",
            # https://discourse.nixos.org/t/trusting-the-remote-store-of-my-own-machines-because-it-lacks-a-signature-by-a-trusted-key/46659/5?u=jfly
            "--no-check-sigs",
        ],
        check=True,
        env={**os.environ, "NIX_SSHOPTS": f"-p {ssh_port}"},
    )
    ssh_and_run(ssh=ssh, ssh_port=ssh_port, command=generate_script)


def move_vars(ssh: str, ssh_port: int):
    print(f"Moving vars on {ssh}:{ssh_port}")
    ssh_and_run(
        ssh=ssh,
        ssh_port=ssh_port,
        command="mkdir /mnt/etc && mv /etc/vars /mnt/etc/vars",
    )


NixosAnywherePhase = Literal["kexec", "disko", "install", "reboot"]


def nixos_anywhere(ssh: str, ssh_port: int, hostname: str, phase: NixosAnywherePhase):
    host_dir = HOSTS_DIR / hostname
    # Note: this regenerates hardware config N times.
    hardware_configuration_path = host_dir / "hardware-configuration.nix"

    subprocess.run(
        [
            "nix",
            "run",
            "github:nix-community/nixos-anywhere",
            "--",
            "--flake",
            f".#{hostname}",
            "--generate-hardware-config",
            "nixos-generate-config",
            hardware_configuration_path,
            "--ssh-port",
            str(ssh_port),
            "--phases",
            phase,
            ssh,
        ],
        check=True,
    )


@main.command()
@click.option("--ssh", required=True)
@click.option("-p", "--ssh-port", type=int, default=22)
@click.argument("hostname")
def bootstrap(ssh: str, ssh_port: int, hostname: str):
    host_dir = HOSTS_DIR / hostname

    if not host_dir.exists():
        raise click.ClickException(
            f"{host_dir} does not exist. Have you created it yet? See `tools/fleet declare`"
        )

    click.echo(f"Bootstrapping {hostname}.")

    nixos_anywhere(ssh=ssh, ssh_port=ssh_port, hostname=hostname, phase="kexec")
    generate_vars(ssh=ssh, ssh_port=ssh_port, hostname=hostname)
    nixos_anywhere(ssh=ssh, ssh_port=ssh_port, hostname=hostname, phase="disko")
    move_vars(ssh=ssh, ssh_port=ssh_port)
    nixos_anywhere(ssh=ssh, ssh_port=ssh_port, hostname=hostname, phase="install")
    nixos_anywhere(ssh=ssh, ssh_port=ssh_port, hostname=hostname, phase="reboot")


if __name__ == "__main__":
    main()
