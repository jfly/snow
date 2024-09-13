{ stdenv }:

# https://www.dafont.com/dk-majolica.font
stdenv.mkDerivation {
  pname = "majolica-font";
  version = "0.0.1";
  buildCommand = ''
    install -m444 -Dt $out/share/fonts/truetype ${./DK-Majolica.otf}
  '';
}
