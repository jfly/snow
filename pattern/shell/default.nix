{ config, lib, pkgs, ... }:

let
  jgit = pkgs.callPackage ../../shared/jgit { };
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
      plugins+=(z)
      plugins+=(fzf)
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      ##################################

      source ${../../shared/homies/zshrc}
      source ${../../shared/homies/commonrc/aliases}
    '';
    promptInit = ''
      # Load p10k prompt
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${../../shared/homies/p10k.zsh}

      #<<< eval "$(starship init zsh)"
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

    #<<< ### Prompt
    #<<< starship

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
