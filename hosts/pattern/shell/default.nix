{ inputs', flake, flake', config, pkgs, ... }:

let
  inherit (flake'.packages)
    jgit
    ;

  shtuff = inputs'.shtuff.packages.default;
in
{
  imports = [
    flake.nixosModules.q
    flake.nixosModules.yazi
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
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      ##################################

      source ${./zshrc}
      source ${./aliases}

      eval "$(zoxide init zsh)"
    '';

    promptInit = ''
      # Load p10k prompt
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${./p10k.zsh}
    '';
  };
  programs.tmux = {
    clock24 = true;
    # Resize the window to the size of the smallest session for which it is the current window.
    aggressiveResize = true;
  };

  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  environment.etc."direnv/direnv.toml".text = ''
    [global]
    strict_env = true

    [whitelist]
    prefix = [
        "~/src/github.com/jfly",
        "~/sync/scratch",
    ]
  '';

  environment.systemPackages = with pkgs; [
    ### sd (script directory)
    flake'.packages.sd

    ### Explore filesystem
    file
    tree
    zoxide
    ripgrep

    ### Misc utils
    q
    jgit
    psmisc # provides pstree
    acpi # check laptop battery
    pwgen
    htop
    moreutils # vidir
    shtuff

    ### data graphing
    (pkgs.writeShellScriptBin "qcsv" ''
      exec ${q-text-as-data}/bin/q "$@"
    '')
    smag
  ];
}
