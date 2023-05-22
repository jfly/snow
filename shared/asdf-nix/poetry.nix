{ pkgs }:

let
  shaByVersion = {
    "1.2.1" = "ODbI8sSBEhvbp8f2K8WCZAN09Khw80SyruWtjoTewoM=";
    "1.2.2" = "huIjLv1T42HEmePCQNJpKnNxJKdyD9MlEtc2WRPOjRE=";
    "1.3.0" = "16ng59ykm7zkjizmwb482y0hawpjjr5mvl0ahjd790xzxcc2bbbv";
    "1.3.2" = "12EiEGI9Vkb6EUY/W2KWeLigxWra1Be4ozvi8njBpEU=";
  };
  # TODO: revisit this once https://github.com/NixOS/nixpkgs/pull/233393 is merged up
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
  derivationByVersion = {
    "1.5.0" = poetry150;
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
