{ stdenv, cmake }:

stdenv.mkDerivation {
  name = "space2meta-speedcubing";
  src = ./.;

  nativeBuildInputs = [
    cmake
  ];
}
