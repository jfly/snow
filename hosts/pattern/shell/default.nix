{
  inputs',
  flake,
  flake',
  config,
  pkgs,
  ...
}:

let
  shtuff = inputs'.shtuff.packages.default;
in
{
  imports = [
    flake.nixosModules.q
    flake.nixosModules.jgit
    flake.nixosModules.yazi
    flake.nixosModules.zoxide
    flake.nixosModules.newpy
    flake.nixosModules.nix-hack
    flake.nixosModules.fzf
  ];

  users.users.${config.snow.user.name}.shell = pkgs.fish;
  programs.fish.enable = true;
  programs.fish.package = pkgs.fish.overrideAttrs (oldAttrs: {
    patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
      # Add history-last-token-search-backward/history-last-token-search-forward
      # https://github.com/fish-shell/fish-shell/issues/10756
      (pkgs.fetchpatch {
        url = "https://github.com/fish-shell/fish-shell/compare/3.7.1...jfly:fish-shell:add-history-last-token-search.patch";
        hash = "sha256-bqL7AmZnQPTQX6dq3GAhCQUTEeau3Qo25brgIdRBVRg=";
      })
    ];
  });
  # Enabling fish enables this setting, and it's slowwww to rebuild. I'm going
  # to try turning it off and see if I regret it.
  # https://discourse.nixos.org/t/slow-build-at-building-man-cache/52365/3
  documentation.man.generateCaches = false;

  programs.zsh = {
    enable = true;
    interactiveShellInit =
      # bash
      ''
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

        source ${./zsh/zshrc}
      '';

    promptInit =
      # bash
      ''
        # Load p10k prompt
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${./zsh/p10k.zsh}
      '';
  };
  programs.tmux = {
    clock24 = true;
    # Resize the window to the size of the smallest session for which it is the current window.
    aggressiveResize = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  environment.etc."direnv/direnv.toml".text =
    # toml
    ''
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
    ripgrep

    ### Misc utils
    q
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
