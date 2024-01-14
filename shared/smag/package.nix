{ fetchFromGitHub, lib, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "smag";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "aantn";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-PdrK4kblXju23suMe3nYFT1KEbyQu4fwP/XTb2kV1fs=";
  };

  cargoHash = "sha256-SX6tOodmB0usM0laOt8mjIINPYbzHI4gyUhsR21Oqrw=";

  meta = with lib; {
    description = "Show Me A Graph - Command Line Graphing";
    homepage = "https://github.com/aantn/smag";
    license = licenses.mit;
    maintainers = [ ];
  };
}
