# A collection of pure nix helper functions to interact with decrypted secrets
# *at nix evaluation time*. This is generally a bad idea: you're almost
# certainly going to leak secrets into /nix/store if you use anything here.
#
# The reason these exist is partly historical (I used to do everything this
# way). I've since moved to following the "best practice" of only putting
# encrypted values in the store, and leaving it to the host machine to decrypt
# them on startup using agenix.
# Unfortunately, I still use these helpers to get secrets onto our
# astro/nix-openwrt-imagebuilder managed routers.

{ inputs, flake, ... }:

let
  inherit (inputs.nixpkgs.lib)
    removeSuffix
    ;
in
rec {
  repoPath = encrypted: (
    let hashed = builtins.hashString "sha256" (removeSuffix "\n" encrypted);
    in "./.sensitive-decrypted-secrets/${hashed}.secret"
  );

  absoluteRepoPath = encrypted: flake.lib.snow.absoluteRepoPath (repoPath encrypted);

  impureString = encrypted: builtins.readFile (absoluteRepoPath encrypted);
}
