{
  lib,
  stdenv,
  fetchurl,
  cmake,
}:
stdenv.mkDerivation (finalAttrs: {
  version = "0.2.0";
  pname = "interception-tools-space2meta";

  src = fetchurl {
    url = "https://gitlab.com/interception/linux/plugins/space2meta/-/archive/v${finalAttrs.version}/space2meta-v${finalAttrs.version}.tar.gz";
    hash = "sha256-dXEtlqkco3e7R5dnJaOedRSA+PYa6pArM3IxCwS0SHo=";
  };

  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
  buildInputs = [ cmake ];

  meta = {
    homepage = "https://gitlab.com/interception/linux/plugins/space2meta";
    description = "Turn your space key into the meta key (a.k.a. win key or OS key) when chorded
to another key (on key release only).";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jfly ];
    platforms = lib.platforms.linux;
  };
})
