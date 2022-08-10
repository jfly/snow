{ dunst, makeWrapper, symlinkJoin }:

let config = ./dunstrc;
in
symlinkJoin {
  name = "dunst";
  paths = [ dunst ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/dunst --add-flags "-config ${config}"
  '';
}
