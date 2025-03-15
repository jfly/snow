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
        name = "services/cloudflare-dyndns: require that apiTokenFile be a api token";
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/388853.patch";
        hash = "sha256-5VXRjeL+EiqgMWN+YWDayZT+jILa+kuXJ5VWAwj7hEA=";
      })
      (fetchpatch {
        name = "fish: 4.0.0 -> 4.0.1";
        url = "https://github.com/nixos/nixpkgs/commit/751d16bea37fd276f1ed495cac9418d7ae97574f.patch";
        hash = "sha256-eLHHmYTpQmfBo2LdoBIvRC3576d12SzFniTI95QDC8I=";
      })
      # From https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:fish-4.1.0-unstable
      # To pull in https://github.com/fish-shell/fish-shell/commit/4ce552bf949a8d09c483bb4da350cfe1e69e3e48
      (fetchpatch {
        name = "fish: 4.0.1 -> 4.1.0-unstable";
        url = "https://github.com/NixOS/nixpkgs/commit/5b6c05e1fb335b90a692131e325885b1e3e481c9.patch";
        hash = "sha256-jDIV3Y6ThblKD7CxvBX9bOdav3+Nkm6ymz2UayjnwqQ=";
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
