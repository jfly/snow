{ pkgs }:

let
  poetry150 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.5.0";
      url = "https://github.com/jfly/nixpkgs/";
      ref = "poetry-1.5.0";
      rev = "6d29570a80e4e65b6adca7a749ecbf87d6427f51";
    })
    {
      localSystem = pkgs.system;
    }).poetry;
  poetry151 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.5.1";
      url = "https://github.com/jfly/nixpkgs/";
      ref = "poetry-1.5.1";
      rev = "b9b02a2c08613fcc626554b3568240f272786834";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  poetry160 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.6.0";
      url = "https://github.com/jfly/nixpkgs/";
      ref = "poetry-1.6.0";
      rev = "8a55bc6f690071108781a3940674726b43a475ef";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  poetry161 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.6.1";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "9957cd48326fe8dbd52fdc50dd2502307f188b0d";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  poetry171 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.7.1";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/master";
      rev = "4e1582c0136f371f68c23074acf8ae22ddb14a0a";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  poetry182 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.8.2";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/master";
      rev = "38d8d0e7ea26033834f8e1138bdeaaa952c6f77b";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  poetry183 = (import
    (builtins.fetchGit {
      name = "nixpkgs-with-poetry-1.8.8";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "05bbf675397d5366259409139039af8077d695ce";
    })
    {
      localSystem = pkgs.system;
    }).poetry;

  derivationByVersion = {
    "1.5.0" = poetry150;
    "1.5.1" = poetry151;
    "1.6.0" = poetry160;
    "1.6.1" = poetry161;
    "1.7.1" = poetry171;
    "1.8.2" = poetry182;
    "1.8.3" = poetry183;
  };
in
version: derivationByVersion.${version}
