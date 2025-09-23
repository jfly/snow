{ stdenv, fetchzip }:

# https://www.freebestfonts.com/gill-sans-font
stdenv.mkDerivation {
  pname = "gill-sans-font";
  version = "0.0.1";
  src = fetchzip {
    url = "https://www.freebestfonts.com/yone/down/GillSans.zip";
    hash = "sha256-YcZUKzRskiqmEqVcbK/XL6ypsNMbY49qJYFG3yZVF78=";
    stripRoot = false;
  };
  buildCommand = ''
    for f in $src/*otf; do
        install -m444 -Dt $out/share/fonts/truetype "$f"
    done
  '';
}
