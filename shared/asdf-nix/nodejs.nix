{ pkgs, callPackage }:

let
  nodejsBuilderByVersion = {
    "14.18.2" = {
      baseDrv = pkgs.nodejs-14_x;
      sha256 = "sha256-Poqc4Q+LzTYo623QSffwPIS6khm+b5dD4iIRVLnMaAs=";
      patches = [ ];
    };
    "16.9.0" = {
      baseDrv = pkgs.nodejs-16_x.override {
        # Node 16.9.0 is particular about the version of Python you use to build it:
        # > Node.js configure: Found Python 3.10.6...
        # > Please use python3.9 or python3.8 or python3.7 or python3.6.
        python3 = pkgs.python39;
      };
      sha256 = "sha256-GudkIA38I6impoOH4+9sfrOHBe/9s4ciydORb+uLZm8=";
      patches = [ ];
    };
    "18.15.0" = {
      baseDrv = pkgs.nodejs-18_x;
      sha256 = "sha256-jkTWUBj/lzKEGVwjGGRpoOpAgul+xCAOX1cG1VhNqjc=";
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
