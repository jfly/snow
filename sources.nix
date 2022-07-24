{
  nixos-21_11 = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/69699c886f9594b86d8afc48d897fb6378784ecb.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1fnq5dsiz4mln37f0mw9sibmx7ap5ff6smkzryyzwqwd5xq3hhjq";
  });
  nixos-unstable = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/2e3f6efdeda4cfff0259912495761885d8bee74a.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0qk9xcnf1jcjlnl651w3nq8snkhx9n4q0zlnvix5xdw66abi1yfp";
  });
  nixos-generators = import (builtins.fetchTarball {
    name = "nixos-generators";
    url = "https://github.com/nix-community/nixos-generators/archive/296067b9c7a172d294831dec89d86847f30a7cfc.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0ngq2jdwcc197bf48hrnwn1w494j4nyznr80lvsfi4pkayr87zyr";
  });
  parsec-gaming = import (builtins.fetchTarball {
    name = "parsec-gaming-nix";
    url = "https://github.com/DarthPJB/parsec-gaming-nix/archive/7ef6e12b98efa8e21c9c33815e64889c7bd2ca2b.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "14yy3sgvjsll5mvbjwdf7ahwdngnfwjvvg48a5zviblpi084zr0p";
  });
}
