{ pkgs, fetchzip }:

let
  shaByVersion = {
    "1.22.15" = "sha256-Zgeralws4dk74QPq/SZAjG7um+/gG20b6EbGzUv5ifc=";
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
