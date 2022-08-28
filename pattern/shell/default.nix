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

  environment.systemPackages = with pkgs; [
    pkgs.fzf
    git
    psmisc
  ];
}
