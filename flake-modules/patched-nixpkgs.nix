{ inputs, ... }:

let
  unpatchedPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  inherit (unpatchedPkgs)
    applyPatches
    fetchpatch
    ;

  patched-nixpkgs = applyPatches {
    name = "nixpkgs-patched";
    src = inputs.nixpkgs;
    patches = [
      (fetchpatch {
        name = "nixos/cloudflare-dyndns: fix missing home error";
        url = "https://github.com/NixOS/nixpkgs/commit/4fac92529970a3b84659260e32bb5cfc0d0afb04.patch";
        hash = "sha256-uq023W+uJqvbWUNZsub1YAlMQ2/wuYHam2rFp9KmkgE=";
      })
      (fetchpatch {
        name = "services/cloudflare-dyndns: require that apiTokenFile be a api token";
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/388853.patch";
        hash = "sha256-5VXRjeL+EiqgMWN+YWDayZT+jILa+kuXJ5VWAwj7hEA=";
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
