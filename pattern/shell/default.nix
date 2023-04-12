{ config, lib, pkgs, ... }:

let
  jgit = pkgs.callPackage ../../shared/jgit { };
in
{
  imports = [
    ../../shared/q
  ];

  programs.zsh.enable = true;
  users.users.${config.snow.user.name}.shell = pkgs.zsh;
  programs.zsh.interactiveShellInit = ''
    # Load p10k prompt
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    source ${../../shared/homies/p10k.zsh}

    # Load ohmyzsh
    plugins=(git)
    plugins+=(z)
    plugins+=(fzf)
    source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh

    source ${../../shared/homies/zshrc}
    source ${../../shared/homies/commonrc/aliases}
  '';

  programs.tmux = {
    clock24 = true;
    # Resize the window to the size of the smallest session for which it is the current window.
    aggressiveResize = true;
  };

  environment.systemPackages = with pkgs; [
    q
    jgit
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
