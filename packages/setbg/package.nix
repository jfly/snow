{ pkgs }:

pkgs.writeShellApplication {
  name = "setbg";
  text = ''
    feh --randomize --bg-fill "$HOME/sync/jfly/wallpaper/"*
  '';
  runtimeInputs = with pkgs; [ feh ];
}
