{ username, ... }:
{ config, lib, ... }:

let
  link = target: {
    source =
      if builtins.pathExists target then
        config.lib.file.mkOutOfStoreSymlink target
      else
        builtins.throw "Could not find ${target}";
  };
  homeDir = "/home/${username}";
in
{
  home.stateVersion = "22.05";
  home.username = username;
  home.homeDirectory = homeDir;

  home.file = (lib.mapAttrs'
    (name: target:
      lib.nameValuePair name (link target))
    {
      ".dotfiles" = ../dotfiles;
      sd = ../dotfiles/homies/sd;
      bin = ../dotfiles/homies/bin;
      ".config/git" = ../dotfiles/homies/config/git;
      ".gitignore_global" = ../dotfiles/homies/gitignore_global;
      ".ssh/config" = ../dotfiles/homies/ssh/config;
      ".ssh/config.d" = ../dotfiles/homies/ssh/config.d;

      # Create and set a custom GTK theme.
      ".themes" = ../dotfiles/homies/themes;
      ".config/gtk-3.0" = ../dotfiles/homies/config/gtk-3.0;

      # Set up direnv.
      # TODO: figure out how to get this confg living closer to the
      # installation of direnv itself.
      ".config/direnv/direnvrc" = ../dotfiles/homies/config/direnv/direnvrc;
      ".config/direnv/direnv.toml" = ../dotfiles/homies/config/direnv/direnv.toml;
      ".config/direnv/lib" = ../dotfiles/homies/config/direnv/lib;

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
        source ${../dotfiles/homies/zshrc}
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
