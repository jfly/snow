if status is-interactive
    source $HOME/.config/fish/nix.fish
    source $HOME/.config/fish/desktop.fish
    source $HOME/.config/fish/git.fish
    source $HOME/.config/fish/docker.fish
    source $HOME/.config/fish/kubernetes.fish
    source $HOME/.config/fish/bigword.fish
    source $HOME/.config/fish/directories.fish

    # This is to get Fish and Neovim behaving the same
    # with "ghost text" completions. See <C-CR> in
    # `packages/neovim/completion/default.nix` for the Neovim side of this.
    bind ctrl-enter forward-char

    # More Zsh/Bash-like behavior for Alt+. and Alt+>
    # See <https://github.com/fish-shell/fish-shell/issues/10756> for details.
    bind alt-. history-last-token-search-backward
    bind alt-\> history-last-token-search-forward

    # I prefer this to the default (clear-commandline) because it lets me see
    # the thing I abandoned.
    bind ctrl-c cancel-commandline

    abbr --add sap 'shtuff as $PWD'
end
