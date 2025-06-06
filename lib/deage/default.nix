{ lib, flake, ... }:

rec {
  repoPath =
    encrypted:
    (
      let
        hashed = builtins.hashString "sha256" (lib.removeSuffix "\n" encrypted);
      in
      "./.sensitive-decrypted-secrets/${hashed}.secret"
    );

  absoluteRepoPath = encrypted: flake.lib.snow.absoluteRepoPath (repoPath encrypted);

  /**
    This function is impure: it requires the ability to read gitignored files
    from the filesystem. The files it reads are decrypted secrets (as decrypted
    by `python -m tools.deage`), so they're very sensitive! You're almost certainly going
    to leak secrets into /nix/store if you this function.

    The reason this exists is to get secrets onto our
    astro/nix-openwrt-imagebuilder managed routers.

    TODO: get rid of this in favor of something like:
    - [Liminix](https://www.liminix.org/)
    - Regular NixOS running on something like a Banana Pi
  */
  impureString = encrypted: builtins.readFile (absoluteRepoPath encrypted);
}
