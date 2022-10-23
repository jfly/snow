{ lib, stdenvNoCC, fetchzip }:

# This is a (probably brittle) derivation to build Google's new-ish monochrome
# Noto Emoji font.
# Nixpkgs doesn't support it yet because Google doesn't seem to have uploaded the font to anywhere on GitHub yet.
# For more information, see:
#   - https://github.com/NixOS/nixpkgs/issues/166953#issuecomment-1116263975
#   - https://github.com/googlefonts/noto-emoji/issues/390

stdenvNoCC.mkDerivation {
  pname = "noto-fonts-emoji-monochrome";
  version = "2022-10-22";

  src = fetchzip {
    url = "https://fonts.google.com/download?family=Noto%20Emoji";
    # Add .zip parameter so that zip unpackCmd can match it.
    extension = ".zip";
    stripRoot = false;
    sha256 = "sha256-q7WpqAhmio2ecNGOI7eX7zFBicrsvX8bURF02Pru2rM=";
  };

  installPhase = ''
    local out_ttf=$out/share/fonts/truetype/noto
    install -m444 -Dt $out_ttf static/*.ttf
  '';

  meta = with lib; {
    description = "Noto emoji, a new black and white emoji font with less color";
    homepage = "https://fonts.google.com/noto/specimen/Noto+Emoji";
    longDescription =
      ''
        Noto Emoji is an open source font that has you covered for all your emoji
        needs, including support for the latest Unicode emoji specification. It
        has multiple weights and features thousands of emoji.
      '';
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = with maintainers; [ mathnerd314 emily ];
  };
}
