let pkgs = (import ./sources.nix).nixos-unstable {};
in

pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.colmena
    pkgs.age
    (pkgs.python3.withPackages (py-pkgs: [py-pkgs.rich]))
    pkgs.kubectl
    (import ./sources.nix).nixos-generators
    pkgs.nixpkgs-fmt
  ];
}
