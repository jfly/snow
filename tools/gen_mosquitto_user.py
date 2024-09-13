#!/usr/bin/env python

from .encrypt import encrypt
from textwrap import indent
import string
import secrets
import subprocess
import tempfile
import argparse


def pwgen() -> str:
    """Generate a password. Copied from https://docs.python.org/3/library/secrets.html"""
    alphabet = string.ascii_letters + string.digits
    password = "".join(secrets.choice(alphabet) for _ in range(20))
    return password


def hash_pw_for_mosquitto(pw: str) -> str:
    with tempfile.NamedTemporaryFile("rt") as pw_file:
        subprocess.run(
            ["mosquitto_passwd", "-b", pw_file.name, "USERNAME", pw],
            check=True,
            text=True,
        )
        _name, hashed_pw = pw_file.read().split(":", maxsplit=1)
        return hashed_pw


def generate(names: list[str]):
    for name in names:
        pw = pwgen()
        hashed_pw = hash_pw_for_mosquitto(pw)
        encrypted = encrypt(hashed_pw)

        conflict_marker_start = ">" * 3
        conflict_marker_end = "<"*3
        py = f'''\
            "{name}": deage(
                # {conflict_marker_start} Unencrypted password (DELETE ME!!!): {pw} {conflict_marker_end}
                """
{indent(encrypted.strip(), " "*16)}
                """
            ),
'''
        print(py, end="")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("user", nargs="+")
    args = parser.parse_args()

    print("Add this stuff to iac/pulumi/app/mosquitto.py\n")
    generate(args.user)


if __name__ == "__main__":
    main()
