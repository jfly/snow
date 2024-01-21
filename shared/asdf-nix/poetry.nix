{ pkgs }:

let
  shaByVersion = {
    "1.2.1" = "ODbI8sSBEhvbp8f2K8WCZAN09Khw80SyruWtjoTewoM=";
    "1.2.2" = "huIjLv1T42HEmePCQNJpKnNxJKdyD9MlEtc2WRPOjRE=";
    "1.3.0" = "16ng59ykm7zkjizmwb482y0hawpjjr5mvl0ahjd790xzxcc2bbbv";
    "1.3.2" = "12EiEGI9Vkb6EUY/W2KWeLigxWra1Be4ozvi8njBpEU=";
  };
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

  derivationByVersion = {
    "1.5.0" = poetry150;
    "1.5.1" = poetry151;
    "1.6.1" = poetry161;
    "1.7.1" = poetry171;
  };
in
version: if builtins.hasAttr version derivationByVersion then derivationByVersion.${version} else
(pkgs.poetry2nix.mkPoetryApplication {
  python = pkgs.python3;
  projectDir = pkgs.fetchFromGitHub {
    owner = "python-poetry";
    repo = "poetry";
    rev = version;
    sha256 = shaByVersion.${version};
    fetchSubmodules = true;
  };

  # Propagating dependencies leaks them through $PYTHONPATH which causes issues
  # when used in nix-shell.
  postFixup = ''
    rm $out/nix-support/propagated-build-inputs
  '';
})
