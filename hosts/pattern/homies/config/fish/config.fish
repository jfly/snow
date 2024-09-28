if status is-interactive
    source $HOME/.config/fish/nix.fish
    source $HOME/.config/fish/desktop.fish
    source $HOME/.config/fish/git.fish
    source $HOME/.config/fish/docker.fish
    source $HOME/.config/fish/kubernetes.fish

    # TODO: remove once we can bind <C-CR> to this instead. See
    # hosts/pattern/homies/config/with-alacritty/default.conf for details.
    bind \cq forward-char
end
