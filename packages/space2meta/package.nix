{
  lib,
  stdenv,
  fetchurl,
  cmake,
}:

let
in
stdenv.mkDerivation (finalAttrs: {
  version = "0.2.0";
  pname = "interception-tools-space2meta";

  src = fetchurl {
    url = "https://gitlab.com/interception/linux/plugins/space2meta/-/archive/v${finalAttrs.version}/space2meta-v${finalAttrs.version}.tar.gz";
    hash = "sha256-dXEtlqkco3e7R5dnJaOedRSA+PYa6pArM3IxCwS0SHo=";
  };

  buildInputs = [ cmake ];

  meta = with lib; {
    homepage = "https://gitlab.com/interception/linux/plugins/space2meta";
    description = "Turn your space key into the meta key (a.k.a. win key or OS key) when chorded
to another key (on key release only).";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
})
