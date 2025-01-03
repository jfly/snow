{ inputs, ... }:

let
  unpatchedPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  inherit (unpatchedPkgs)
    fetchpatch
    applyPatches
    ;

  patched-nixpkgs = applyPatches {
    name = "nixpkgs-patched";
    src = inputs.nixpkgs;
    patches = [
      # https://github.com/NixOS/nixpkgs/pull/341086
      (fetchpatch {
        name = "upower: Upgrade to 1.90.6 and extend CriticalPowerActions";
        url = "https://github.com/NixOS/nixpkgs/pull/341086.patch";
        hash = "sha256-F/viEIWqJup/0llSWcGYlFl9LXq1UYHURcIbSzbp15E=";
      })
      # https://github.com/NixOS/nixpkgs/pull/369019
      (fetchpatch {
        name = "byzanz: fix build";
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/369019.patch";
        hash = "sha256-nkYNt5NElOzTo/H/BOw+G3zW9IZF2auVrXOeNaw7hPA=";
      })
      (fetchpatch {
        name = "sane-frontends: fix gcc14 compilation";
        url = "https://github.com/NixOS/nixpkgs/commit/6b1e48102d5d5d4b5cf1440713016d988b352e36.patch";
        hash = "sha256-KOrowivGArI6ON2ksOIkzqW1OArUpjiD/CxGwnvR3/w=";
      })
      (fetchpatch {
        name = "goocanvas2: fix gcc14 compilation";
        url = "https://github.com/NixOS/nixpkgs/commit/1edac59cc67598d3c5179d7090a98e308b7a2da7.patch";
        hash = "sha256-+ccYl8VnovTOd+aSQbqgzILpaY46o7uImIQrCq+ZMd0=";
      })
    ];
  };
in
{
  _module.args.patched-nixpkgs = patched-nixpkgs;

  perSystem =
    { system, ... }:
    {
      # Override the [default nixpkgs instance][0] to be an instance of our
      # patched nixpkgs.
      #
      # Yes, this is dreaded import from derivation (IFD)!
      #
      # [0]: https://github.com/hercules-ci/flake-parts/blob/bcef6817a8b2aa20a5a6dbb19b43e63c5bf8619a/modules/nixpkgs.nix#L18-L22
      _module.args.pkgs = import patched-nixpkgs { inherit system; };
    };
}
