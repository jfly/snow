{ substituteAll
, dunst
, dmenu
, makeWrapper
, symlinkJoin
, xdg-utils
, lib
}:

let
  config = substituteAll
    {
      src = ./dunstrc;
      inherit dmenu;
      xdg_utils = xdg-utils;
    };
in
symlinkJoin {
  name = "dunst";
  paths = [
    (dunst.overrideAttrs (oldAttrs: {
      patches = [
        # TODO: see if we can upstream this to dunst?
        ./search-symbolic-icons.patch
      ];
    }))
  ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/dunst \
        --add-flags "-config ${config}"
  '';
}
