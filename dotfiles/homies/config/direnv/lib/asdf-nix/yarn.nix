{ pkgs, fetchzip }:

let
  shaByVersion = {
    "1.22.17" = "sha256-cvsgEPlh4B/jEsLQboO2xMslhSAkuWFAoMucJLanf+o=";
  };
in
version: pkgs.yarn.overrideAttrs (oldAttrs: {
  version = version;
  src = fetchzip {
    url = "https://github.com/yarnpkg/yarn/releases/download/v${version}/yarn-v${version}.tar.gz";
    sha256 = shaByVersion.${version};
  };
})
