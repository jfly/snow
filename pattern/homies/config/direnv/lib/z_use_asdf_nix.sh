# shellcheck shell=bash

# This file is carefully named to come alphabetically after use_asdf.sh.
# This provides an alternative implementation of `use_asdf` that's built on top
# of nix rather than asdf-vm + asdf-direnv.

# Rename the "real" `use_asdf` to `og_use_asdf`
eval og_"$(declare -f use_asdf)"

use_asdf() {
    # If USE_REAL_ASDF=1 is set, use the original use_asdf instead.
    if [ -n "${USE_REAL_ASDF-}" ]; then
        og_use_asdf "$@"
        return $?
    fi

    watch_file .tool-versions
    # We can't use $(direnv_layout_dir) here because nix is smart enough to
    # realize that's (usually) inside of a git repo and it's gitignored, so
    # none it ends up in the nix store.
    asdf_nix_dir="${XDG_DATA_HOME:-$HOME/.local/share}/asdf-nix/$(md5sum ./.tool-versions | cut -f 1 -d " ")"
    if [ ! -d "$asdf_nix_dir" ]; then
        mkdir -p "$asdf_nix_dir"

        # Follow our system's nixpkgs version. This should increase cache hits.
        nixpkgs_rev=$(nix eval --raw --impure --expr '(builtins.getFlake "/home/jeremy/src/github.com/jfly/snow").inputs.nixos-unstable.rev')
        cat <<EOF >"$asdf_nix_dir/flake.nix"
{
  description = "asdf-nix dev environment autogenerated by use_asdf";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/${nixpkgs_rev}";
    flake-utils.url = "github:numtide/flake-utils";
    asdf-nix-flake.url = "github:jfly/snow?dir=shared/asdf-nix";
    # asdf-nix-flake.url = "path:$HOME/src/github.com/jfly/snow/shared/asdf-nix";
    asdf-nix-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, asdf-nix-flake }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.\${system};
          asdf-nix = asdf-nix-flake.lib.\${system};
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = (asdf-nix.pkgs {
                tool-versions = ''
$(cat ./.tool-versions)
'';
            });
          };
        }
      );
}
EOF
    fi
    echo "Loading flake from $asdf_nix_dir"

    # Needed to get python2 working :cry:
    export NIXPKGS_ALLOW_INSECURE=1
    # --impure needed so we can read the NIXPKGS_ALLOW_INSECURE env var.
    use_flake "$asdf_nix_dir" "$@" --impure
}
