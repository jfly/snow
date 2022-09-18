{ pkgs }:

pkgs.writeShellApplication {
  name = "setbg";
  text = ''
    feh --randomize --bg-fill "$HOME/sync/wallpaper/"*
  '';
  runtimeInputs = with pkgs; [ feh ];
}
