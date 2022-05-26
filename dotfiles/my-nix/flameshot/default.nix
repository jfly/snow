{ pkgs }:

let
  patched_flameshot = pkgs.flameshot.overrideAttrs (oldAttrs: {
    patches = [
      ./0000-issue-1072-workaround.diff
      ./0001-issue-2283-workaround.diff
    ];
  });
  config = ./flameshot.ini;
  config_dir = pkgs.runCommand "flameshot-config-home" { } ''
    mkdir -p $out/flameshot
    cp ${config} $out/flameshot/flameshot.ini
  '';

in

pkgs.symlinkJoin {
  name = "flameshot";
  paths = [ patched_flameshot ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/flameshot --set XDG_CONFIG_DIRS ${config_dir}
  '';
}
