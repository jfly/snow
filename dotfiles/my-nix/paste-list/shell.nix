{ pkgs ? import <nixpkgs> {} }:

let deps = (import ./default.nix { inherit pkgs; }).deps;
in

pkgs.mkShell {
  buildInputs = [
    (deps.python.withPackages (p: (deps.py-packages p) ++ [p.black]))
  ];
}
