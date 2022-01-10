{
  pkgs ? (import ./sources.nix).pkgs {}
}:

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.morph
    pkgs.age
    (pkgs.python3.withPackages (py-pkgs: [py-pkgs.rich]))
  ];
}
