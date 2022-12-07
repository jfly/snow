{ pkgs ? import <nixpkgs> { } }:

with pkgs.python3Packages; buildPythonApplication rec {
  pname = "imap-strip-attachments";
  version = "1.0";
  format = "pyproject";

  nativeBuildInputs = [
    setuptools
    black
    isort
  ];
  propagatedBuildInputs = [
    imapclient
    beautifulsoup4
    tqdm
  ];
  src = ./.;

  shellHook = "";
}
