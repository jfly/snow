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
      (fetchpatch {
        name = "cryptpad: add missing x2t.js";
        url = "https://github.com/NixOS/nixpkgs/commit/74e9258a0b4fc6bca5574307a26b6193819348e3.patch";
        hash = "sha256-kDhbkwhoDXuhhzWadFHj7DaHcedXSMBe4/8HpEzcFe8=";
      })
      # https://github.com/NixOS/nixpkgs/pull/365514
      (fetchpatch {
        name = "cryptpad: verify that we've installed the correct versions of OnlyOffice";
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/365514.patch";
        hash = "sha256-Xbu4BSG5NYswk5Hv9Yhbw2LVMqSMhK6IFMz/PNHUbtA=";
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
