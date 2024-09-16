import os
from hashlib import sha256
from textwrap import dedent

DECRYPTED_SECRETS_DIR = "../../.sensitive-decrypted-secrets"


def deage(encrypted: str):
    encrypted = dedent(encrypted).strip()
    hash_encrypted = sha256(encrypted.encode("utf8")).hexdigest()
    secret_file = os.path.join(DECRYPTED_SECRETS_DIR, f"{hash_encrypted}.secret")
    with open(secret_file, "r") as f:
        return f.read()
