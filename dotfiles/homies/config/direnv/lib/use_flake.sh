use_flake() {
    # Copied from https://github.com/direnv/direnv/wiki/Nix#hand-rolled-nix-flakes-integration
    # This will not prevent garbage collection, look into nix-direnv if that's an issue.

    # This is a workaround for https://github.com/NixOS/nix/issues/6809
    # TODO: remove if this PR gets deployed and released! :crossed-fingers:
    export XDG_DATA_DIRS=${XDG_DATA_DIRS:-}

    # reload when these files change
    watch_file flake.nix
    watch_file flake.lock
    # load the flake devShell
    eval "$(nix print-dev-env)"
}
