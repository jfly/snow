{ stdenv, python3, cmake, lib }:

stdenv.mkDerivation {
  name = "space2meta-speedcubing";
  src = ./.;

  nativeBuildInputs = [
    cmake
  ];
}
