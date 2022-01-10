{
  pkgs = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/f60477f2546e7b41bf0593535c9d1e4471e4df8e.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1wgjycla0i4rpgnpnx8dsr7h2wrwjq3gl6b39snrimj8r9kaa4g4";
  });
  nixos-generators = import (builtins.fetchTarball {
    name = "nixos-generators";
    url = "https://github.com/nix-community/nixos-generators/archive/296067b9c7a172d294831dec89d86847f30a7cfc.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0ngq2jdwcc197bf48hrnwn1w494j4nyznr80lvsfi4pkayr87zyr";
  });
}
