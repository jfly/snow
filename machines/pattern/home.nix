{ flake, config, ... }:
let
  outerConfig = config;
in
{
  config,
  lib,
  pkgs,
  ...
}:

let
  link = target: {
    source = config.lib.file.mkOutOfStoreSymlink target;
  };
  homeDir = "/home/${outerConfig.snow.user.name}";
in
{
  home.stateVersion = "22.05";
  home.username = outerConfig.snow.user.name;
  home.homeDirectory = homeDir;

  # TODO: move to pattern/desktop/ somehow.
  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;

    package = pkgs.quintom-cursor-theme;
    name = "Quintom_Ink";
    size = 45;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/mailto" = [ "chromium-browser.desktop" ];
    };
  };

  home.file =
    (lib.mapAttrs (name: target: (link target)) {
      sd = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/sd";
      bin = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/bin";
      ".config/git" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/config/git";
      ".config/fish" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/config/fish";
      ".config/with-alacritty" =
        flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/config/with-alacritty";
      ".gitignore_global" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/gitignore_global";
      ".ssh/config" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/ssh/config";
      ".ssh/config.d" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/ssh/config.d";

      # Create and set a custom GTK theme.
      ".themes" = flake.lib.snow.absoluteRepoPath "/machines/pattern/homies/themes";

      # Secrets
      ".android/adbkey" = "${homeDir}/sync/jfly-linux-secrets/.android/adbkey";
      ".android/adbkey.pub" = "${homeDir}/sync/jfly-linux-secrets/.android/adbkey.pub";
      ".config/adept" = "${homeDir}/sync/jfly-linux-secrets/.config/adept";
    })
    // {
      ".zshrc".text = ''
        # zsh really wants this file to exist. If it doesn't, it'll give
        # us a friendly (but *annoying*) welcome message.
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

        # Need to check for _DID_SYSTEMD_CAT to avoid double sourcing.
        # This is a workaround for
        # https://github.com/NixOS/nixpkgs/issues/188545.
        if [ -z "$_DID_SYSTEMD_CAT" ]; then
          export PATH=$HOME/bin:$PATH
        fi
      '';
      ".zprofile".text = ''
        source $HOME/.profile
      '';
      ".docker/config.json".text = builtins.toJSON {
        "detachKeys" = "ctrl-^,q";
      };
    };

  gtk = {
    enable = true;
    gtk3 = {
      bookmarks = [
        "file:///home/jeremy/tmp"
        "file:///home/jeremy/Downloads"
        "file:///home/jeremy/scans"
        "file:///home/jeremy/sync/jfly/screenshots"
        "file:///home/jeremy/sync"
      ];
      extraCss = ''
        * {
            /*
             * Tell applications that they should render symbolic tray icons rather than regular icons.
             * TODO: can we scope this to polybar somehow? Maybe we can actually make
             *       this a polybar setting?
             * https://mail.gnome.org/archives/gtk-devel-list/2014-May/msg00020.html
             */
            -gtk-icon-style: symbolic;
        }
      '';
    };
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

    "org/gnome/desktop/interface" = {
      "gtk-key-theme" = "Emacs";
    };
  };
}
