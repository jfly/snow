# shellcheck shell=bash

if [ -z "${USE_REAL_ASDF-}" ]; then
    # This file is carefully named to come alphabetically after use_asdf.sh.
    # This provides an alternative implementation of `use_asdf` that's built on top
    # of nix rather than asdf-vm + asdf-direnv.
    use_asdf() {
        watch_file .tool-versions
        # We can't use $(direnv_layout_dir) here because nix is smart enough to
        # realize that's (usually) inside of a git repo and it's gitignored, so
        # none it ends up in the nix store.
        asdf_nix_dir="${XDG_DATA_HOME:-$HOME/.local/share}/asdf-nix/$(md5sum ./.tool-versions | cut -f 1 -d " ")"
        if [ ! -d "$asdf_nix_dir" ]; then
            mkdir -p "$asdf_nix_dir"

            cat <<EOF >"$asdf_nix_dir/flake.nix"
{
  description = "asdf-nix dev environment autogenerated by use_asdf";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    # asdf-nix-flake.url = "github:jfly/snow?dir=shared/asdf-nix";
    asdf-nix-flake.url = "path:$HOME/src/github.com/jfly/snow/shared/asdf-nix";
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

            # This doesn't work: setting LD_LIBRARY_PATH like this breaks
            # things when we're trying to run multiple applications compiled
            # with different versions of glibc. I think the right fix is to
            # actually patchelf all the .so files we pip installed to be
            # statically linked to the appropriate libraries. see
            # ~/sync/scratch/jfly/notes/2022-09-26-python-patching-nixos.md
            # for a proof of concept of how to do this. i think we could make
            # this a lot smoother, and even do some clever patch to pip to make
            # this "just work"
            # # Python wheels expect to be able to find shared libs in /usr/lib,
            # # but NixOS is special and those files don't exist. See
            # # https://www.breakds.org/post/build-python-package/#the-package-is-built-successfully-but-it-panics-about-not-finding-libstdcso6-when-being-imported
            # # for details and a neat solution using autoPatchelfHook. However,
            # # if we're using regular old venvs and pip, we don't have an
            # # opportunity to patch wheels. Maybe there's something clever we
            # # could do by providing a wrapper on top of pip? For now it's
            # # working well enough to just set LD_LIBRARY_PATH.
            # LD_LIBRARY_PATH = pkgs.stdenv.cc.cc.lib + /lib;

            # Hack alert: accumulation-tree doesn't provide a prebuilt wheel,
            # and it needs <crypt.h>, which is provided by libxcrypt.
            # There probably is a more canonical way of getting this stuff
            # available to gcc, but this is good enough for now.
            CPATH = pkgs.libxcrypt + /include;
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
fi
