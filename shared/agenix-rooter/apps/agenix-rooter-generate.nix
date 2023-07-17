{ outputs, pkgs, flakeRoot, ... }:

let
  inherit
    (pkgs.lib)
    concatLists
    concatMapStrings
    concatStringsSep
    escapeShellArg
    filter
    flatten
    mapAttrsToList
    removeSuffix
    substring
    unique
    warn
    ;

  rooter-lib = pkgs.callPackage ../lib.nix { };

  hostData = hostName: host:
    if host.config ? age then
      mapAttrsToList
        (_: secret:
          {
            inherit hostName;
            rooterFile = secret.rooterFile;
            # Destination for the re-encrypted secret, releative to the root of the current repo (flake).
            relDest = rooter-lib.relativePath {
              from = flakeRoot;
              to = pkgs.lib.path.append
                host.config.age.rooter.generatedForHostDir
                (rooter-lib.generatedSecretFilename host.config secret);
            };
            hostPubkey = host.config.age.rooter.hostPubkey;
          }
        )
        host.config.age.secrets
    else warn "ignoring host '${hostName}' as it appears to not use agenix" [ ];
  secretsData = flatten (mapAttrsToList hostData outputs.nixosConfigurations);
  toPython = val:
    let f = builtins.toFile "nix2py" (builtins.toJSON val);
    in "json.loads(Path('${f}').read_text())  # noqa: E501";
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
    src: Path,
    decrypt_privkey: Path,
    dest: Path,
    encrypt_pubkey: str,
  ):
      decrypt_process = subprocess.Popen(
          ["${pkgs.age}/bin/age", "--decrypt", "--identity", decrypt_privkey, src],  # noqa: E501; yes, it's a long line
          stdout=subprocess.PIPE,
      )
      encrypt_process = subprocess.Popen(
          ["${pkgs.age}/bin/age", "--encrypt", "--armor", "--recipient", encrypt_pubkey, "--output", dest],  # noqa: E501; yes, it's a long line
          stdin=decrypt_process.stdout,
      )
      # Allow p1 to receive a SIGPIPE if p2 exits.
      # https://docs.python.org/3/library/subprocess.html#replacing-shell-pipeline
      decrypt_process.stdout.close()
      check_wait(decrypt_process)
      check_wait(encrypt_process)


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
          current = set(f for f in dest_dir.iterdir())
          desired = set(s['relDest'] for s in secret_by_dest.values())

          missings = desired - current
          extras = current - desired

          for missing in missings:
              secret = secret_by_dest[missing]
              rooter_file = secret['rooterFile']
              host_name = secret['hostName']
              host_pubkey = secret['hostPubkey']
              root_key = Path(".sensitive-decrypted-secrets/age-private-key.txt")

              print(f"Reencrypting for {host_name!r} {rooter_file} -> {missing}")
              if not dry_run:
                  reencrypt(
                      src=rooter_file,
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
