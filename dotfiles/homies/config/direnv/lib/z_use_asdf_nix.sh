# This file is carefully named to come alphabetically after use_asdf.sh.
# This provides an alternative implementation of `use_asdf` that's built on top
# of nix rather than asdf-vm + asdf-direnv.
use_asdf() {
    # Based off of `use_nix` from the direnv stdlib
    local dirname
    dirname=$(dirname "${BASH_SOURCE[0]}")
    direnv_load nix-shell --show-trace -I nixpkgs=/home/jeremy/src/github.com/NixOS/nixpkgs -E "with import <nixpkgs> {}; let asdf = pkgs.callPackage $dirname/asdf-nix {}; in asdf.shell ./.tool-versions" --run "$(join_args "$direnv" dump)"
}
