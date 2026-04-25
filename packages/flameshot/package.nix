{
  flameshot,
  symlinkJoin,
  makeWrapper,
  runCommand,
}:

let
  config = ./flameshot.ini;
  configDir = runCommand "flameshot-config-home" { } ''
    mkdir -p $out/flameshot
    cp ${config} $out/flameshot/flameshot.ini
  '';

in

symlinkJoin {
  name = "flameshot";
  paths = [ flameshot ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/flameshot --set XDG_CONFIG_DIRS ${configDir}
  '';
}
