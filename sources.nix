rec {
  nixos-21_11 = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/69699c886f9594b86d8afc48d897fb6378784ecb.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1fnq5dsiz4mln37f0mw9sibmx7ap5ff6smkzryyzwqwd5xq3hhjq";
  });
  nixos-unstable = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/f3d0897be466aa09a37f6bf59e62c360c3f9a6cc.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0zch1dhd4mc84jx7cl0qarxjwkyf90qsxkpbwa2nlzgdjb459zyk";
  });
  nixos-generators = import (builtins.fetchTarball {
    name = "nixos-generators";
    url = "https://github.com/nix-community/nixos-generators/archive/296067b9c7a172d294831dec89d86847f30a7cfc.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0ngq2jdwcc197bf48hrnwn1w494j4nyznr80lvsfi4pkayr87zyr";
  });
  parsec-gaming = import (builtins.fetchTarball {
    name = "parsec-gaming-nix";
    url = "https://github.com/jfly/parsec-gaming-nix/archive/61dfa8d291109cd755573e9011edd249f90ddf8c.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1ibpfybwj3z7gnyk6gk1wsyqz5nv432x1a4rxzqkcc2mjssl7yj4";
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
  home-manager-unstable = import (home-manager-unstable-tarball + "/home-manager/home-manager.nix");
  home-manager-nixos = import (home-manager-unstable-tarball + "/nixos");
}
