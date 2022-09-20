rec {
  nixos-21_11 = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/69699c886f9594b86d8afc48d897fb6378784ecb.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1fnq5dsiz4mln37f0mw9sibmx7ap5ff6smkzryyzwqwd5xq3hhjq";
  });
  nixos-unstable = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/f677051b8dc0b5e2a9348941c99eea8c4b0ff28f.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "18zycb8zxnz20g683fgbvckckr7rmq7c1gf96c06fp8pmaak0akx";
  });
  parsec-gaming = import (builtins.fetchTarball {
    name = "parsec-gaming-nix";
    url = "https://github.com/jfly/parsec-gaming-nix/archive/fc5e2e2898bf6802925b05e2d376944beaab2474.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1338ga70pmmld020zc407qqgk9f5dnpmr9nmbcrlz8rrwls5zv00";
  });
  nixgl = import (builtins.fetchTarball {
    name = "nixGL";
    url = "https://github.com/guibou/nixGL/archive/17658df1e17a64bc23ee5c93cfa9e8b663a4ac81.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "18adz8bli9gq619mm8y7m8irjbh9dg0mg31wrrcrky7w3al8g7ph";
  });
  home-manager-unstable-tarball = builtins.fetchTarball
    {
      name = "home-manager-unstable";
      url = "https://github.com/nix-community/home-manager/archive/8675cfa549e1240c9d2abb1c878bc427eefcf926.tar.gz";
      # Hash obtained using `nix-prefetch-url --unpack <url>`
      sha256 = "0lw47ddid8x7cfg1c26h8v52x9nl667p0ha78rgvyxd6j6si8126";
    };
  home-manager-modules = import (home-manager-unstable-tarball + "/modules");
  home-manager-nixos = import (home-manager-unstable-tarball + "/nixos");
}
