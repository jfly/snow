{ pkgs, lib, stdenv }:

stdenv.mkDerivation rec {
  pname = "sd";
  version = "1.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "ianthehenry";
    repo = "sd";
    rev = "v${version}";
    sha256 = "sha256-128lpy9DGDOft3jOmJXRuHLLiqDrT4m4NfzkNg0AtaQ=";
  };

  strictDeps = true;
  buildInputs = [ pkgs.bash ];

  installPhase = ''
    mkdir -p $out/bin
    cp sd $out/bin/sd
    mkdir -p $out/share/zsh/site-functions
    cp _sd $out/share/zsh/site-functions/_sd
  '';

  meta = {
    description = "sd: my script directory";
    homepage = "https://github.com/ianthehenry/sd";
    license = lib.licenses.mit;
  };
}
