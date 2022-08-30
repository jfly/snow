{ pkgs }:

pkgs.writeShellApplication {
  name = "setbg";
  text = ''
    feh --randomize --bg-fill "$HOME/wallpaper/"*
  '';
  runtimeInputs = with pkgs; [ feh ];
}
