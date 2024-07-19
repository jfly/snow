{ pkgs, callPackage }:

let
  derivationByVersion = {
    "18.15.0" = (import
      (builtins.fetchGit {
        # Descriptive name to make the store path easier to identify
        name = "my-old-revision";
        url = "https://github.com/NixOS/nixpkgs/";
        ref = "refs/heads/nixpkgs-unstable";
        rev = "1b7a6a6e57661d7d4e0775658930059b77ce94a4";
      })
      {
        localSystem = pkgs.system;
      }).nodejs;
  };
  nodejsBuilderByVersion = {
    "20.14.0" = {
      baseDrv = pkgs.nodejs_20;
      sha256 = "sha256-CGVQKPDYQ26IFj+RhgRNY10/Nqhe5Sjza9BbbF5Gwbs=";
      patches = [ ];
    };
  };
in
version: (
  if builtins.hasAttr version derivationByVersion then derivationByVersion.${version} else
  let builder = nodejsBuilderByVersion.${version};
  in
  builder.baseDrv.overrideAttrs (oldAttrs: {
    inherit version;
    src = pkgs.fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
      sha256 = builder.sha256;
    };
    patches = builder.patches;
  })
)
