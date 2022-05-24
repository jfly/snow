default:
    just --list

check:
    nixpkgs-fmt --check .

fix:
    nixpkgs-fmt .
