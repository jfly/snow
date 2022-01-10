{
  pkgs = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/f60477f2546e7b41bf0593535c9d1e4471e4df8e.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1wgjycla0i4rpgnpnx8dsr7h2wrwjq3gl6b39snrimj8r9kaa4g4";
  });
}
