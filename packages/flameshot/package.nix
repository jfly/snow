{ pkgs }:

let
  patchedFlameshot = pkgs.flameshot.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./0000-issue-1072-workaround.diff
      # Fix for really terrible quality screenshots: <https://github.com/flameshot-org/flameshot/issues/4172>
      (pkgs.fetchpatch {
        url = "https://github.com/flameshot-org/flameshot/commit/06f41a86cc91d53d68871fcdc67053239ff1e87b.diff";
        hash = "sha256-UbXziDTbVeK/WqTTTgowClPu7Ky9cht7BAdYl6xUtIg=";
      })
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
