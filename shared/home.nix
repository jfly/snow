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

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/mailto" = [ "chromium-browser.desktop" ];
    };
  };

  home.file = (lib.mapAttrs'
    (name: target:
      lib.nameValuePair name (link target))
    {
      sd = pkgs.snow.absoluteRepoPath "/shared/homies/sd";
      bin = pkgs.snow.absoluteRepoPath "/shared/homies/bin";
      ".config/git" = pkgs.snow.absoluteRepoPath "/shared/homies/config/git";
      ".gitignore_global" = pkgs.snow.absoluteRepoPath "/shared/homies/gitignore_global";
      ".ssh/config" = pkgs.snow.absoluteRepoPath "/shared/homies/ssh/config";
      ".ssh/config.d" = pkgs.snow.absoluteRepoPath "/shared/homies/ssh/config.d";

      # Create and set a custom GTK theme.
      ".themes" = pkgs.snow.absoluteRepoPath "/shared/homies/themes";
      ".config/gtk-3.0" = pkgs.snow.absoluteRepoPath "/shared/homies/config/gtk-3.0";

      # Set up direnv.
      # TODO: figure out how to get this config living closer to the
      # installation of direnv itself.
      ".config/direnv/direnvrc" = pkgs.snow.absoluteRepoPath "/shared/homies/config/direnv/direnvrc";
      ".config/direnv/direnv.toml" = pkgs.snow.absoluteRepoPath "/shared/homies/config/direnv/direnv.toml";
      ".config/direnv/lib" = pkgs.snow.absoluteRepoPath "/shared/homies/config/direnv/lib";

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

    ".config/.wallabag.secrets".text = (
      let
        clientId = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAwaThYNXlOK213eG1CWXJo
          L3lmY2FubFpZNSt5TjRNTHliOVIyd3JRNWpRClVjaEFId3pCZ0x6dUpNM0tNbVdC
          N3V0enFhSm1PdzB1TzYxeE41K29DbjAKLS0tIDZvSUhyeFpOMlE3UnVTa2RXSEQx
          VUMxejBvMG4yczRuMjNmbHZXMG1uc00K8cRL8BXiKSfxNW/hA7FGHfI1NOr+kake
          1dD0jivvNdvaLKAqSYzNNGn3AQf8Rog5zHFsDJ/tZ4KoDNg1U0A5YxcRhGT1XG2A
          57CSkBLsqJXXec0=
          -----END AGE ENCRYPTED FILE-----
        '';
        clientSecret = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTUFJYZTYzcXFTb0FXMmxp
          UFdMcE1mcGswR20vWDd3U3JsRllqbGtJTmljCjQ3K0dqTkhiRGVESnhUODd5R3dx
          TUpNMjExZmx1Yi9TQTRTRGJNTiswOEEKLS0tIHMwUHRxeXpGNDl6RlVQMUkwbGs5
          eDF2VFB4V0lta3dJUVFkRnZxbkdZUjAKYhmIWKfzrGSDX5wqcUHRGMAbBHkH/c7R
          /GHCIdnYAgScpSqoZYuCLwuEyi52mUQwBcdPu+a0MCeRO8sW3FCPe5i1C74u+YsY
          xRR7qslieC4E6A==
          -----END AGE ENCRYPTED FILE-----
        '';
        username = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAxTkxWK3M0eXR3Ukd3eDd1
          T000U3p2VmFlNjgvYUhiMGdYOTdwaFZuUXhZCkFiSjZtMVJlTytSckFmaGFlNmY5
          L0UwUmdvVGE3WjVpYzBMMHFaRFl0RU0KLS0tIFpxRTlWUXhzUXVoMTY3cC9ZM2t2
          MmVOa2ErdDdEY005RDlhNVRwcWNMV2cKDdBPq0i7XCStd08I3oLyYrwHM5Bu3GBJ
          2/4s68mEBKzsugvN
          -----END AGE ENCRYPTED FILE-----
        '';
        password = pkgs.deage.string ''
          -----BEGIN AGE ENCRYPTED FILE-----
          YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBOUTFJRjB2Y1VEWlBvL253
          blpNdHF5WldieFR2ejVTMkJmeVk0a3Nob2pVClpQMGpSaC8wRkl6eUlxdGxDTGNQ
          di82M3E4MGZFSzA0Z3lSaUZrMUFDbWMKLS0tIGtUT3NuZEh5UCtvcGcvbk1GanBW
          SzMrc1JSR2dKMmZZRUNVTFpGTkdiNVUKoPhfYJ5kfy2/5X2g6tSS5tsgU+ckNb+E
          Y4bXJtWzd1WadB3swYV6Wtp8DTxkC9A=
          -----END AGE ENCRYPTED FILE-----
        '';
      in
      ''
        export WALLABAG_CLIENT_ID=${clientId}
        export WALLABAG_CLIENT_SECRET=${clientSecret}
        export WALLABAG_USERNAME=${username}
        export WALLABAG_PASSWORD=${password}
      ''
    );
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
