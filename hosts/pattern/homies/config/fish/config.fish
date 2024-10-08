if status is-interactive
    source $HOME/.config/fish/nix.fish
    source $HOME/.config/fish/desktop.fish
    source $HOME/.config/fish/git.fish
    source $HOME/.config/fish/docker.fish
    source $HOME/.config/fish/kubernetes.fish
    source $HOME/.config/fish/bigword.fish
    source $HOME/.config/fish/directories.fish

    # TODO: remove once we can bind <C-CR> to this instead. See
    # hosts/pattern/homies/config/with-alacritty/default.conf for details.
    bind \cq forward-char

    # More Zsh/Bash-like behavior for Alt+.
    # See <https://github.com/fish-shell/fish-shell/issues/10756> for details.
    bind \e. history-last-token-search-backward
    bind \e\> history-last-token-search-forward

    abbr --add sap 'shtuff as $PWD'
end
