path_prepend() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1${PATH:+":$PATH"}"
    fi
}

# Reset the PATH.
export PATH=""

# This is where pacman installs things.
path_prepend "/usr/bin"

# nix-env installs binaries here.
path_prepend "$HOME/.nix-profile/bin"

# Useful scripts managed in my dotfiles repo.
path_prepend "$HOME/bin"

# asdf is installed here. Note: we're very intentionally *not* adding the asdf
# shims directory. Instead, direnv will automatically put the correct versions
# of tools in our PATH as needed.
path_prepend "$HOME/.asdf/bin"
