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
    ./ripgrep.nix
  ];

  users.users.${config.snow.user.name}.shell = pkgs.fish;
  programs.fish.enable = true;
  # Enabling fish enables this setting, and it's slowwww to rebuild. I'm going
  # to try turning it off and see if I regret it.
  # https://discourse.nixos.org/t/slow-build-at-building-man-cache/52365/3
  documentation.man.cache.enable = false;

  programs.tmux = {
    clock24 = true;
    # Resize the window to the size of the smallest session for which it is the current window.
    aggressiveResize = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    settings = {
      global.strict_env = true;
      whitelist.prefix = [
        "~/src/github.com/jfly"
        "~/sync/scratch"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    ### sd (script directory)
    flake'.packages.sd

    ### Explore filesystem
    file
    tree
    flake'.packages.src-report
    inputs'.devshell-init.packages.default

    ### Misc utils
    q
    psmisc # provides pstree
    flake'.packages.childpids
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
