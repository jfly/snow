{ fetchFromGitHub, lib, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "smag";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "aantn";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-AR9+kKSKwah4am7pQjiwjda2cYFcRSzMVGuYzpI+G04=";
  };

  cargoHash = "sha256-G0baatyGgKYB1Y8Ja2BSNzwGCpzL+SjDxCAWqQ7J/yw=";

  meta = with lib; {
    description = "Show Me A Graph - Command Line Graphing";
    homepage = "https://github.com/aantn/smag";
    license = licenses.mit;
    maintainers = [];
  };
}
