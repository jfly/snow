{
  fetchFromGitHub,
  lib,
  stdenv,
}:

let
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gaidns";
  version = "0-unstable-2020-01-24";

  src = fetchFromGitHub {
    owner = "sleirsgoevy";
    repo = "gaidns";
    rev = "9c2b9cb2f0e1269fac142bb237d1bd3a1823565b";
    hash = "sha256-ZBgLcp/2GqIkF8hl35Z1C1XUlYDfXwO6C9yfYo9vDcY=";
  };

  installPhase = ''
    mkdir -p $out/bin
    mv gaidns $out/bin/gaidns
  '';

  meta = {
    description = "getaddrinfo-based dns server";
    homepage = "https://github.com/sleirsgoevy/gaidns";
    # TODO: could not find a license
    mainProgram = "gaidns";
    maintainers = [ lib.maintainers.jfly ];
    platforms = lib.platforms.all;
  };
})
