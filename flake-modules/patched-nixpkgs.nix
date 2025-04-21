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
      # From https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:fish-4.1.0-unstable
      # To pull in https://github.com/fish-shell/fish-shell/commit/4ce552bf949a8d09c483bb4da350cfe1e69e3e48
      (fetchpatch {
        name = "fish: 4.0.1 -> 4.1.0-unstable";
        url = "https://github.com/NixOS/nixpkgs/commit/5b6c05e1fb335b90a692131e325885b1e3e481c9.patch";
        hash = "sha256-jDIV3Y6ThblKD7CxvBX9bOdav3+Nkm6ymz2UayjnwqQ=";
      })
      (fetchpatch {
        name = "cloudflare-dyndns: 5.0 -> 5.3";
        url = "https://github.com/NixOS/nixpkgs/pull/394352.patch";
        hash = "sha256-D00nFseHun4J+eopACFPxtrP0s+94Q5SbcuRkKPrWIw=";
      })
      (fetchpatch {
        name = "postsrsd: 1.12 -> 2.0.10 + corresponding service changes";
        url = "https://github.com/NixOS/nixpkgs/pull/397316.patch";
        hash = "sha256-HKbcagytkr3iKL4T+eod/v1Ns2fD27DgKMRby6PWWvk=";
      })
      (fetchpatch {
        name = "nixos/restic-rest-server Fixed htpasswd-path when null.";
        url = "https://github.com/NixOS/nixpkgs/commit/b539e4848f5695992ea0963f4640b245d5b598d9.patch";
        hash = "sha256-nOSDGRJien4Ahz6RN3XE5Xe4VZBa5lUG9o12Shc/q8w=";
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
