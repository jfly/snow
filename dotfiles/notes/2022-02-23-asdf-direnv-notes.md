# 2022-02-23 15:14 -0800: setup on m1 mac

Install plugin, plus latest version:

    asdf plugin-add direnv
    asdf install direnv latest
    asdf global direnv latest

Remove all this from `~/.zshrc`:

    eval "$(pyenv init --path)"
    eval "$(pyenv virtualenv-init -)"

    . /opt/homebrew/opt/asdf/asdf.sh

Add this in its place:

    ### Set up asdf+direnv
    eval "$(asdf exec direnv hook zsh)"
    direnv() { asdf exec direnv "$@"; }

Set up some conf:

    $ mkdir -p ~/.config/direnv
    $ echo 'source "$(asdf direnv hook asdf)"' >> ~/.config/direnv/direnvrc

Teach direnv to trust the directory where you clone your joinhonor code. For example:

    cat ~/.config/direnv/direnv.toml
    [whitelist]
    prefix = [
        "/home/jeremy/src/github.com/joinhonor",
        "/home/jeremy/src/scratch",
    ]

Open a new terminal. Notice no shims!

    jeremyfleischman@Jeremys-MacBook-Pro ~ % echo $PATH
    /opt/homebrew/opt/bison/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
