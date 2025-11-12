{ pkgs }:

let
  patchedFlameshot = pkgs.flameshot.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0000-issue-1072-workaround.diff
    ];
  });
  config = ./flameshot.ini;
  configDir = pkgs.runCommand "flameshot-config-home" { } ''
    mkdir -p $out/flameshot
    cp ${config} $out/flameshot/flameshot.ini
  '';

in

pkgs.symlinkJoin {
  name = "flameshot";
  paths = [ patchedFlameshot ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/flameshot --set XDG_CONFIG_DIRS ${configDir}
  '';
}
