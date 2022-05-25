{
  nixos-21_11 = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/69699c886f9594b86d8afc48d897fb6378784ecb.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1fnq5dsiz4mln37f0mw9sibmx7ap5ff6smkzryyzwqwd5xq3hhjq";
  });
  nixos-unstable = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/dfd82985c273aac6eced03625f454b334daae2e8.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1ipd1k1gvxh9sbg4w4cpa3585q09gvsq8xbjvxnnmfjib6r6xx4i";
  });
  nixos-generators = import (builtins.fetchTarball {
    name = "nixos-generators";
    url = "https://github.com/nix-community/nixos-generators/archive/296067b9c7a172d294831dec89d86847f30a7cfc.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0ngq2jdwcc197bf48hrnwn1w494j4nyznr80lvsfi4pkayr87zyr";
  });
}
