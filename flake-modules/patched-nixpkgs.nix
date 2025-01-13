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
        name = "upower: 1.90.4 -> 1.90.6";
        url = "https://github.com/NixOS/nixpkgs/commit/5c4767a41c3132c0327a9ea9c420893bf7eaa60a.patch";
        hash = "sha256-zM7iPxJieiHYoWUgpS9A2iLuGEmbBzScu3SoXjcr3RI=";
      })
      # Fix broken `Image-Magick` build, which affects `gscan2pdf`
      # https://github.com/NixOS/nixpkgs/pull/372231
      (fetchpatch {
        name = "perlPackages.ImageMagick: use same version as main imagemagick package";
        url = "https://github.com/NixOS/nixpkgs/pull/372231.patch";
        hash = "sha256-mwQh1UJDvIEbLrmxPfZDvuZnVI/nLya3Vjx0vodCVsE=";
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
