{
  replaceVars,
  dunst,
  dmenu,
  makeWrapper,
  symlinkJoin,
  xdg-utils,
}:

let
  config = replaceVars ./dunstrc {
    inherit dmenu;
    xdg_utils = xdg-utils;
  };
in
symlinkJoin {
  name = "dunst";
  paths = [
    dunst
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/dunst \
        --add-flags "-config ${config}"
  '';
}
