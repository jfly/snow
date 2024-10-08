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
      (fetchpatch {
        name = "latest inkscape/silhouette unstable";
        url = "https://github.com/jfly/nixpkgs/commit/653dd896a6cb28f2bc206dc8566348e649bea7d4.patch";
        hash = "sha256-/NJqA1zYJ+uYMQ3tV9zyUG6n4LqeIjcyvvfSr07BVps=";
      })
      # https://github.com/NixOS/nixpkgs/pull/341086
      (fetchpatch {
        name = "upower: Upgrade to 1.90.6 and extend CriticalPowerActions";
        url = "https://github.com/NixOS/nixpkgs/pull/341086.patch";
        hash = "sha256-Fcqi/M3Cmdrq/RxWuVTne/Os6LbCw3NFqVUYGIZ54YA=";
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
