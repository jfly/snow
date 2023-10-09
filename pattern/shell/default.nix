{ config, lib, pkgs, stdenv, ... }:

let
  jgit = pkgs.callPackage ../../shared/jgit { };
  my-yazi = pkgs.callPackage ../../shared/my-yazi { };
in
{
  imports = [
    ../../shared/q
  ];

  users.users.${config.snow.user.name}.shell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      ###
      ### Powerlevel10k
      ###
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      if [[ -r "$${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$${(%):-%n}.zsh" ]]; then
          source "$${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-$${(%):-%n}.zsh"
      fi
      ##################################

      ###
      ### Load ohmyzsh
      ###
      plugins=(git)
      plugins+=(fzf)
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      ##################################

      source ${../../shared/homies/zshrc}
      source ${../../shared/homies/commonrc/aliases}
      ${my-yazi.zshrc}
    '';
    promptInit = ''
      # Load p10k prompt
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${../../shared/homies/p10k.zsh}

      # TODO: re-investigate starship sometime
      # eval "$(starship init zsh)"

      eval "$(zoxide init zsh)"
    '';
  };
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

    ### Prompt
    # TODO: re-investigate starship sometime
    # starship

    ### Explore filesystem
    file
    tree
    my-yazi.drv
    zoxide

    ### Misc utils
    psmisc # provides pstree
    acpi # check laptop battery
    pwgen
    htop
  ];
}
