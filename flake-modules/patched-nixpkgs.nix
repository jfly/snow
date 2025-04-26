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
        name = "cloudflare-dyndns: 5.0 -> 5.3";
        url = "https://github.com/NixOS/nixpkgs/commit/24f9910708d0d38c0e0cd9cc863bde4149b48fb6.patch";
        hash = "sha256-D00nFseHun4J+eopACFPxtrP0s+94Q5SbcuRkKPrWIw=";
      })
      (fetchpatch {
        name = "postsrsd: 1.12 -> 2.0.10 + corresponding service changes";
        url = "https://github.com/NixOS/nixpkgs/pull/397316.patch";
        hash = "sha256-ZKzzqBI4m3lK/mxJEorrCUEFHJXVUjefD5o0P7Q752Y=";
      })
      (fetchpatch {
        name = "services(cloudflare-dyndns): use new `CLOUDFLARE_API_TOKEN_FILE` setting";
        url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:use-new-cloudflare-dyndns-option.patch";
        hash = "sha256-XjrjEqkTxc+HPZZNtacNkPrbAhd+DNVo3HPBLzHgxVs=";
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
