{ username, ... }:
{ config, ... }:

let
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.stateVersion = "22.05";
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.file.sd.source = link ../dotfiles/homies/sd;
  home.file.bin.source = link ../dotfiles/homies/bin;

  # zsh really wants this file to exist. If it doesn't, it'll give
  # us a friendly (but *annoying*) welcome message.
  home.file.".zshrc".text = "";
  home.file.".profile".text = ''
    # Need to check for _DID_SYSTEMD_CAT to avoid double sourcing.
    # This is a workaround for
    # https://github.com/NixOS/nixpkgs/issues/188545.
    if [ -z "$_DID_SYSTEMD_CAT" ]; then
      export PATH=$HOME/bin:$PATH
    fi
  '';
  home.file.".zprofile".text = ''
    source $HOME/.profile
  '';
}
