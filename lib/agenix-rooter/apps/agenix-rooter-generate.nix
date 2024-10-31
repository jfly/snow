{
  flake,
  pkgs,
  flakeRoot,
  ...
}:

let
  inherit (pkgs.lib)
    flatten
    mapAttrsToList
    warn
    ;

  rooter-lib = pkgs.callPackage ../lib.nix { };

  hostData =
    hostName: host:
    if host.config ? age then
      mapAttrsToList (_: secret: {
        inherit hostName;
        rooterEncrypted = secret.rooterEncrypted;
        # Destination for the re-encrypted secret, relative to the root of the current repo (flake).
        relDest = rooter-lib.relativePath {
          from = flakeRoot;
          to = pkgs.lib.path.append host.config.age.rooter.generatedForHostDir (
            rooter-lib.generatedSecretFilename host.config secret
          );
        };
        hostPubkey = host.config.age.rooter.hostPubkey;
      }) host.config.age.secrets
    else
      warn "ignoring host '${hostName}' as it appears to not use agenix" [ ];
  secretsData = flatten (mapAttrsToList hostData flake.nixosConfigurations);
  toPython =
    val:
    let
      f = builtins.toFile "nix2py" (builtins.toJSON val);
    in
    "json.loads(Path('${f}').read_text())  # noqa: E501";
in

pkgs.writers.writePython3 "agenix-rooter-generate" { } ''
  import json
  import argparse
  import subprocess
  from pathlib import Path


  def check_wait(p):
      p.wait()
      if p.returncode:
          raise subprocess.CalledProcessError(
              p.returncode,
              p.args,
              p.stdout,
              p.stderr,
          )


  def reencrypt(
    encrypted_data: Path,
    decrypt_privkey: Path,
    dest: Path,
    encrypt_pubkey: str,
  ):
      # Create directory for reencrypted file if it doesn't exist yet.
      dest.parent.mkdir(parents=True, exist_ok=True)
      decrypt_process = subprocess.Popen(
          ["${pkgs.age}/bin/age", "--decrypt", "--identity", decrypt_privkey],  # noqa: E501; yes, it's a long line
          stdin=subprocess.PIPE,
          stdout=subprocess.PIPE,
          text=True,
      )
      encrypt_process = subprocess.Popen(
          ["${pkgs.age}/bin/age", "--encrypt", "--armor", "--recipient", encrypt_pubkey, "--output", dest],  # noqa: E501; yes, it's a long line
          stdin=decrypt_process.stdout,
      )
      # Allow p1 to receive a SIGPIPE if p2 exits.
      # https://docs.python.org/3/library/subprocess.html#replacing-shell-pipeline
      decrypt_process.stdout.close()
      decrypt_process.communicate(encrypted_data)
      check_wait(decrypt_process)
      check_wait(encrypt_process)

      subprocess.run(["git", "add", "--intent-to-add", dest], check=True)


  def sync(dry_run: bool):
      secret_by_dest_by_dest_dir = {}

      flake_root = ${toPython flakeRoot}
      flake_root = Path(flake_root)
      secrets = ${toPython secretsData}
      for secret in secrets:
          rel_dest = Path(secret['relDest'])
          secret['relDest'] = rel_dest

          dest_dir = rel_dest.parent
          if dest_dir not in secret_by_dest_by_dest_dir:
              secret_by_dest_by_dest_dir[dest_dir] = {}

          assert rel_dest not in secret_by_dest_by_dest_dir[dest_dir]
          secret_by_dest_by_dest_dir[dest_dir][rel_dest] = secret

      for dest_dir, secret_by_dest in secret_by_dest_by_dest_dir.items():
          if dest_dir.exists():
              current = set(f for f in dest_dir.iterdir())
          else:
              current = set()
          desired = set(s['relDest'] for s in secret_by_dest.values())

          missings = desired - current
          extras = current - desired

          for missing in missings:
              secret = secret_by_dest[missing]
              rooter_encrypted = secret['rooterEncrypted']
              host_name = secret['hostName']
              host_pubkey = secret['hostPubkey']

              # TODO: make the root key for decryption configurable.
              root_key = Path(".sensitive-decrypted-secrets/age-private-key.txt")

              print(f"Reencrypting for {host_name!r} {missing}")
              if not dry_run:
                  reencrypt(
                      encrypted_data=rooter_encrypted,
                      decrypt_privkey=root_key,
                      dest=missing,
                      encrypt_pubkey=host_pubkey,
                  )

          for extra in extras:
              print(f"Deleting extra file: {str(extra)}")
              if not dry_run:
                  extra.unlink()

          if len(missings) == 0 and len(extras) == 0:
              print("Nothing to do! Done reencrypting secrets.")
          else:
              print("Done reencrypting secrets!")


  def main():
      parser = argparse.ArgumentParser()
      parser.add_argument("--dry-run", "-n", action="store_true")

      args = parser.parse_args()
      sync(dry_run=args.dry_run)


  if __name__ == "__main__":
      main()
''
