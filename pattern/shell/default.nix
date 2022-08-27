{ config, lib, pkgs, ... }:

{
  programs.zsh.enable = true;
  users.users.${config.snow.user.name}.shell = pkgs.zsh;
  programs.zsh.interactiveShellInit = ''
    # Load p10k prompt
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${../../dotfiles/homies/p10k.zsh}

    # Load ohmyzsh
    plugins=(git)
    plugins+=(z)
    plugins+=(fzf)
    source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh

    source ${../../dotfiles/homies/zshrc}
    source ${../../dotfiles/homies/commonrc/aliases}

    # Basic idea copied from https://ianthehenry.com/posts/how-to-learn-nix/nix-zshell/
    export NIX_BUILD_SHELL=${./nix-zshell}
  '';

  # zsh really wants this file to exist. If it doesn't, it'll give us a
  # friendly (but *annoying*) welcome message.
  snow.user.file.".zshrc".text = "";
  snow.user.file.".profile".text = ''
    # Need to check for _DID_SYSTEMD_CAT to avoid double sourcing.
    # This is a workaround for
    # https://github.com/NixOS/nixpkgs/issues/188545.
    if [ -z "$_DID_SYSTEMD_CAT" ]; then
      export PATH=$HOME/bin:$PATH
    fi
  '';
  snow.user.file.".zprofile".text = ''
    source $HOME/.profile
  '';

  environment.systemPackages = with pkgs; [
    pkgs.fzf
    git
    psmisc
  ];
}
