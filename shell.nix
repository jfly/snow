{
  pkgs ? import (builtins.fetchTarball {
    name = "jfly-nixos-21.11";
    url = "https://github.com/jfly/nixpkgs/archive/0229e39c316e882ca3884712690c8833207ea8ff.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "173d00jq26n2v9m6glglkph742l422q2vn45agh7x3aw3c23vl6a";
  }) {}
}:

pkgs.mkShell {
  nativeBuildInputs = [ pkgs.morph ];
}
