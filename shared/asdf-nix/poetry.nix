{ pkgs }:

let
  shaByVersion = {
    "1.2.1" = "ODbI8sSBEhvbp8f2K8WCZAN09Khw80SyruWtjoTewoM=";
    "1.3.0" = "16ng59ykm7zkjizmwb482y0hawpjjr5mvl0ahjd790xzxcc2bbbv";
    "1.3.2" = "12EiEGI9Vkb6EUY/W2KWeLigxWra1Be4ozvi8njBpEU=";
  };
in
version: (pkgs.poetry2nix.mkPoetryApplication {
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
