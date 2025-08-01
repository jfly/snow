#!/usr/bin/env python

import os
import re
import sys
import subprocess
from rich.console import Console
from .encrypt import decrypt
from hashlib import sha256
from textwrap import dedent
from pathlib import Path

AGE_ARMOR_RE = re.compile(
    r"^(?P<ws_prefix> *)-----BEGIN AGE ENCRYPTED FILE-----.*?-----END AGE ENCRYPTED FILE-----",
    re.DOTALL | re.MULTILINE,
)

stderr = Console(file=sys.stderr)


def root() -> Path:
    return Path(
        subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True
        ).strip()
    )


DECRYPTED_SECRETS_DIR = root() / ".sensitive-decrypted-secrets"
PRIVATE_KEY_PATH = DECRYPTED_SECRETS_DIR / "age-private-key.txt"


def extract_and_decrypt_secrets(src: Path):
    document = src.read_text()

    for m in AGE_ARMOR_RE.finditer(document):
        encrypted = dedent(m.group(0))
        hash_encrypted = sha256(encrypted.encode("utf8")).hexdigest()
        decrypted = decrypt(encrypted)
        secret_file = DECRYPTED_SECRETS_DIR / f"{hash_encrypted}.secret"
        with open(secret_file, "w") as f:
            f.write(decrypted)

        secret_file.chmod(0o640)


def sanity_check_private_key():
    private_key_problem = None
    if not PRIVATE_KEY_PATH.is_file():
        private_key_problem = f"Could not find {PRIVATE_KEY_PATH}"
    elif PRIVATE_KEY_PATH.stat().st_size == 0:
        private_key_problem = f"{PRIVATE_KEY_PATH} is empty!"

    if private_key_problem is not None:
        PRIVATE_KEY_PATH.parent.mkdir(parents=True, exist_ok=True)

        stderr.print(f"[bold red]{private_key_problem}[/bold red]")
        stderr.print("")
        stderr.print("Have you successfully decrypted the age private key?")
        stderr.print("")
        # Using `out` rather than `print` to avoid line wrapping.
        stderr.out(
            f"    age --decrypt --identity ~/sync/jfly-linux-secrets/.ssh/id_ed25519 tools/age-private-key.txt.age > {PRIVATE_KEY_PATH}"
        )
        sys.exit(1)


def deage_file(aged_file: Path):
    assert aged_file.suffix == ".aged"

    deaged_file = aged_file.with_suffix(".secret")
    aged_doc = aged_file.read_text()

    def decrypt_match(m):
        prefix = m.group("ws_prefix")
        encrypted = dedent(m.group(0))
        return prefix + decrypt(encrypted)

    deaged_doc = AGE_ARMOR_RE.sub(decrypt_match, aged_doc)
    deaged_file.write_text(deaged_doc)


def main():
    sanity_check_private_key()

    for root, _, files in os.walk("."):
        for file in files:
            path = Path(root) / file
            if path.suffix == ".secret":
                path.unlink()

    for root, _, files in os.walk("."):
        for file in files:
            path = Path(root) / file
            if path.suffix in [".nix", ".py"]:
                extract_and_decrypt_secrets(path)
            elif file.endswith(".aged"):
                deage_file(path)


if __name__ == "__main__":
    main()
