{ pkgs, callPackage }:

let
  nodejsBuilderByVersion = {
    "18.15.0" = {
      baseDrv = pkgs.nodejs_18;
      sha256 = "sha256-jkTWUBj/lzKEGVwjGGRpoOpAgul+xCAOX1cG1VhNqjc=";
      patches = [ ];
    };
    "20.14.0" = {
      baseDrv = pkgs.nodejs_20;
      sha256 = "sha256-CGVQKPDYQ26IFj+RhgRNY10/Nqhe5Sjza9BbbF5Gwbs=";
      patches = [ ];
    };
  };
in
version: (
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
