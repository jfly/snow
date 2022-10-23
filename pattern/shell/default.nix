{ config, lib, pkgs, ... }:

let
  q = pkgs.callPackage ../../shared/q { };
in
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
  '';

  programs.tmux = {
    clock24 = true;
    # Resize the window to the size of the smallest session for which it is the current window.
    aggressiveResize = true;
  };

  environment.systemPackages = with pkgs; [
    q
    pkgs.fzf
    direnv

    ### Explore filesystem
    file
    tree

    ### Misc utils
    psmisc # provides pstree
    acpi # check laptop battery
    pwgen
    htop
  ];
}
