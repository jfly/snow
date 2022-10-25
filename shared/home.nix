{ config, ... }:
let outerConfig = config;
in
{ config, lib, pkgs, ... }:

let
  # TODO: move this docker configuration closer to where we actually install
  # docker.
  docker-conf = builtins.toJSON {
    "credHelpers" = {
      "900965112463.dkr.ecr.us-west-2.amazonaws.com" = "ecr-login";
    };
    "auths" = {
      "containers.clark.snowdon.jflei.com" = {
        "auth" = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBtdUNCWjkrU1VqVndNMDhF
          SjN0emN4UHZnaWJ1MUNXOC9hUytheE8xTDJFCk1OOHpidm0zbGd5d3BFaVZKSU51
          NXRuRlJRNFRYRUxNR2g1Y3ZMTEpJaWsKLS0tIHBGTWRUQjh6bGc4WWJDbThOM1FJ
          ZUFYeWc0a1pXUXliLy9IN3E4czFmWWsKa5YmXKdvYuW9Dm/z9KE+SCvjXZYzq+Up
          naqZkJUsz/p4wjD/jvBYADdyFf76HD7yPXU18ulbwq9gTU3SaK2PzQ==
          -----END AGE ENCRYPTED FILE-----
        '';
      };
    };
    "detachKeys" = "ctrl-^,q";
  };
  link = target: {
    source =
      if builtins.pathExists target then
        config.lib.file.mkOutOfStoreSymlink target
      else
        builtins.throw "Could not find ${target}";
  };
  homeDir = "/home/${outerConfig.snow.user.name}";
in
{
  home.stateVersion = "22.05";
  home.username = outerConfig.snow.user.name;
  home.homeDirectory = homeDir;

  # TODO: move to desktop.nix somehow.
  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;

    package = pkgs.quintom-cursor-theme;
    name = "Quintom_Ink";
    size = 45;
  };

  home.file = (lib.mapAttrs'
    (name: target:
      lib.nameValuePair name (link target))
    {
      sd = ./homies/sd;
      bin = ./homies/bin;
      ".config/git" = ./homies/config/git;
      ".gitignore_global" = ./homies/gitignore_global;
      ".ssh/config" = ./homies/ssh/config;
      ".ssh/config.d" = ./homies/ssh/config.d;

      # Create and set a custom GTK theme.
      ".themes" = ./homies/themes;
      ".config/gtk-3.0" = ./homies/config/gtk-3.0;

      # Set up direnv.
      # TODO: figure out how to get this config living closer to the
      # installation of direnv itself.
      ".config/direnv/direnvrc" = ./homies/config/direnv/direnvrc;
      ".config/direnv/direnv.toml" = ./homies/config/direnv/direnv.toml;
      ".config/direnv/lib" = ./homies/config/direnv/lib;

      # Secrets
      ".ssh/id_rsa" = "${homeDir}/sync/linux-secrets/.ssh/id_rsa";
      ".ssh/id_rsa.pub" = "${homeDir}/sync/linux-secrets/.ssh/id_rsa.pub";
      ".ssh/known_hosts" = "${homeDir}/sync/linux-secrets/.ssh/known_hosts";
      ".gnupg" = "${homeDir}/sync/linux-secrets/.gnupg";
      ".android/adbkey" = "${homeDir}/sync/linux-secrets/.android/adbkey";
      ".android/adbkey.pub" = "${homeDir}/sync/linux-secrets/.android/adbkey.pub";
    }) // {
    ".zshrc".text = ''
      if [ "$(hostname)" = "dalinar" ]; then
        source ${./homies/zshrc}
      else
        true
        # zsh really wants this file to exist. If it doesn't, it'll give
        # us a friendly (but *annoying*) welcome message.
      fi
    '';
    ".profile".text = ''
      ###
      ### Misc default programs
      ###
      export VISUAL=vim
      export EDITOR=vim

      if [ -n "$DISPLAY" ]; then
          export BROWSER=chromium
      else
          export BROWSER=elinks
      fi
      ##################################

      if [ "$(hostname)" = "dalinar" ]; then
        # Start with a fresh PATH.
        export PATH=""

        source ~/.commonrc/path.sh

        ###
        ### Workaround for that ridiculous Java bug on xmonad
        ### https://wiki.archlinux.org/index.php/Java#Applications_not_resizing_with_WM.2C_menus_immediately_closing
        ###
        export _JAVA_AWT_WM_NONREPARENTING=1

        # startx at login
        [[ -z $DISPLAY && $XDG_VTNR -eq 1 && -z $TMUX ]] && exec startx
      else
        # Need to check for _DID_SYSTEMD_CAT to avoid double sourcing.
        # This is a workaround for
        # https://github.com/NixOS/nixpkgs/issues/188545.
        if [ -z "$_DID_SYSTEMD_CAT" ]; then
          export PATH=$HOME/bin:$PATH
        fi
      fi
    '';
    ".zprofile".text = ''
      source $HOME/.profile
    '';
    # Configure Docker.
    # TODO: figure out how to get this config living closer to the
    # installation of docker itself.
    ".docker/config.json".text = docker-conf;
  };

  dconf.settings = {
    # Note: mcg defaults to connecting to localhost:6600 over ipv6,
    # which doesn't work. Changing the hostname to 127.0.0.1 works
    # around the issue.
    # TODO: figure out how to get this configuration closer to
    # pattern/audio.nix, where mpc and mcg are installed.
    "xyz/suruatoel/mcg" = {
      host = "127.0.0.1";
    };
  };
}
