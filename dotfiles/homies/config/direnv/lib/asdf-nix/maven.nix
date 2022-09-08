{ pkgs }:

let
  shaByVersion = {
    "3.8.4" = "sha256-LNycUZQnuyD9wlvvWpBjt5Dkq9kw57FLTp9IY9b58Tw=";
  };
in
version: pkgs.maven.overrideAttrs (oldAttrs: {
  version = version;
  src = pkgs.fetchurl {
    url = "mirror://apache/maven/maven-3/${version}/binaries/${oldAttrs.pname}-${version}-bin.tar.gz";
    sha256 = shaByVersion.${version};
  };
})
