{
  nixpkgs = import (builtins.fetchTarball {
    name = "nixpkgs-unstable";
    url = "https://github.com/NixOS/nixpkgs/archive/abfd31179174133ab8131139d650297bf4da63b7.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "1jmkz6l7sj876wzyn5niyfaxshbmw9fp3g8r41k1wbjvmm5xrnsn";
  });
  nixgl = import (builtins.fetchTarball {
    name = "nixGL";
    url = "https://github.com/guibou/nixGL/archive/17658df1e17a64bc23ee5c93cfa9e8b663a4ac81.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "18adz8bli9gq619mm8y7m8irjbh9dg0mg31wrrcrky7w3al8g7ph";
  });
}
