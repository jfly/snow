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
      # To pull in https://github.com/fish-shell/fish-shell/commit/4ce552bf949a8d09c483bb4da350cfe1e69e3e48
      (fetchpatch {
        name = "fish: 4.0.2 -> 4.1.0-unstable";
        url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:fish-4.1.0-unstable.diff";
        hash = "sha256-ROfdjyjPmGP7L2uxldeyB6TVUul4IiBxyDz30t+LqFQ=";
      })
      (fetchpatch {
        name = "k3s: use patched util-linuxMinimal";
        url = "https://github.com/NixOS/nixpkgs/pull/407810.diff";
        hash = "sha256-N8tzwSZB9d4Htvimy00+Jcw8TKRCeV8PJWp80x+VtSk=";
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
