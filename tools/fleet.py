#!/usr/bin/env python

import click
import shutil
import tempfile
import subprocess
from pathlib import Path
from textwrap import dedent

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
    host_dir = HOSTS_DIR / hostname
    if host_dir.exists():
        if force:
            shutil.rmtree(host_dir)
        else:
            raise click.ClickException(
                f"{host_dir} already exists. Use --force to overwrite."
            )

    template_host_dir = HOSTS_DIR / "template"

    host_dir.mkdir()
    shutil.copy(template_host_dir / "configuration.nix", host_dir / "configuration.nix")
    shutil.copy(template_host_dir / "disko-config.nix", host_dir / "disko-config.nix")

    click.echo(
        dedent(
            f"""
            Successfully generated {host_dir}. Next steps:

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


@main.command()
@click.option("--ssh", required=True)
@click.argument("hostname")
def bootstrap(ssh: str, hostname: str):
    host_dir = HOSTS_DIR / hostname

    if not host_dir.exists():
        raise click.ClickException(
            "{host_dir} does not exist. Have you created it yet? See `tools/fleet declare`"
        )

    hardware_configuration_path = host_dir / "hardware-configuration.nix"

    click.echo(
        f"Bootstrapping {hostname}. This should create {hardware_configuration_path}."
    )
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
            ssh,
        ]
    )


if __name__ == "__main__":
    main()
