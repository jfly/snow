{ pkgs, fetchzip }:

let
  shaByVersion = {
    "1.22.15" = "sha256-Zgeralws4dk74QPq/SZAjG7um+/gG20b6EbGzUv5ifc=";
    "1.22.17" = "sha256-cvsgEPlh4B/jEsLQboO2xMslhSAkuWFAoMucJLanf+o=";
  };
in
version: (pkgs.yarn.override {
  # This is sort of strange: yarn really wants to run using whatever version
  # of nodejs you're actually using in your project. At the very least, its
  # "check engines" feature looks at the version of node you're using to run
  # *yarn*, as opposed to whatever the `node` binary happens to point at. :shrug:
  # Fortunately, nix's yarn package can be configured to use a "system"
  # install of node by just nulling out nodejs. Sweet!
  # Trick copied from https://github.com/NixOS/nixpkgs/issues/53820#issuecomment-617973476
  nodejs = null;
}).overrideAttrs (oldAttrs: {
  version = version;
  src = fetchzip {
    url = "https://github.com/yarnpkg/yarn/releases/download/v${version}/yarn-v${version}.tar.gz";
    sha256 = shaByVersion.${version};
  };
})
