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
in
{
  home.stateVersion = "22.05";
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.file = (lib.mapAttrs'
    (name: target:
      lib.nameValuePair name (link target))
    {
      sd = ../dotfiles/homies/sd;
      bin = ../dotfiles/homies/bin;
      ".config/git" = ../dotfiles/homies/config/git;
      ".gitignore_global" = ../dotfiles/homies/gitignore_global;
    }) // {
    # zsh really wants this file to exist. If it doesn't, it'll give
    # us a friendly (but *annoying*) welcome message.
    ".zshrc".text = "";
    ".profile".text = ''
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
  };

}
