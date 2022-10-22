rec {
  nixos-21_11 = import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/69699c886f9594b86d8afc48d897fb6378784ecb.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1fnq5dsiz4mln37f0mw9sibmx7ap5ff6smkzryyzwqwd5xq3hhjq";
  });
  nixos-unstable = import (builtins.fetchTarball {
    name = "nixos-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/301aada7a64812853f2e2634a530ef5d34505048.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "07y10kplajgysb6491hmksq4gqsiyibia83m3blcxicwyld455km";
  });
  parsec-gaming = import (builtins.fetchTarball {
    name = "parsec-gaming-nix";
    url = "https://github.com/jfly/parsec-gaming-nix/archive/af687d7b9a5412a69c8e1b9ba9f4355047c80d91.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0fg20ghlnmycj0w52ccshblbnmhjb5xxa72jwa8xk9apf2z4wi47";
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
      url = "https://github.com/nix-community/home-manager/archive/69d19b9839638fc487b370e0600a03577a559081.tar.gz";
      # Hash obtained using `nix-prefetch-url --unpack <url>`
      sha256 = "0cqwv3wl1hn3pc3v5scpi041ak8d66r42dj06jhb1cxlsibv4rin";
    };
  home-manager-modules = import (home-manager-unstable-tarball + "/modules");
  home-manager-nixos = import (home-manager-unstable-tarball + "/nixos");
}
