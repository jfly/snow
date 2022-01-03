let
  pkgs = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/f60477f2546e7b41bf0593535c9d1e4471e4df8e.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1wgjycla0i4rpgnpnx8dsr7h2wrwjq3gl6b39snrimj8r9kaa4g4";
  }) {
    config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "parsec"
    ];
    # Patch python rxv package. We can remove this once
    # https://github.com/wuub/rxv/pull/90 is merged up, released, and nixpkgs
    # has been updated to use it.
    overlays = [(
      self: super:
      rec {
        python3 = super.python3.override {
          # Careful, we're using a different self and super here!
          packageOverrides = self: super: {
            rxv = super.rxv.overridePythonAttrs(old: rec {
              version = "0.7.0+PR10-do-not-assume-assertions-are-enabled";
              src = pkgs.fetchFromGitHub {
                owner = "jfly";
                repo = "rxv";
                rev = "do-not-assume-assertions-are-enabled";
                sha256 = "0da43lm4zzrmr95vv86gffmfrwcz6v6g5sdkm67jjhw3lhihwx6s";
              };
            });
          };
        };
        python3Packages = python3.pkgs;
      }
    )];
  };
in
{
  network = {
    inherit pkgs;
  };
  "dallben" = import dallben/configuration.nix;
  "fflewddur" = import fflewddur/configuration.nix;
}
