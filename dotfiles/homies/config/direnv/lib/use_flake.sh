use_flake() {
    # Copied from https://github.com/direnv/direnv/wiki/Nix#hand-rolled-nix-flakes-integration
    # This will not prevent garbage collection, look into nix-direnv if that's an issue.

    # reload when these files change
    watch_file flake.nix
    watch_file flake.lock
    # load the flake devShell
    eval "$(nix print-dev-env)"
}
