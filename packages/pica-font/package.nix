{ stdenv }:

stdenv.mkDerivation {
  pname = "pica-font";
  version = "0.0.1";
  buildCommand = ''
    install -m444 -Dt $out/share/fonts/truetype ${./Pica.ttf}
  '';
}
