{
  pkgs,
  formats,
  makeWrapper,
  runCommand,
  symlinkJoin,
  beetsConfig,
}:

let
  yaml = formats.yaml { };
  config = yaml.generate "config.yaml" beetsConfig;
  configDir = runCommand "config-dir" { } ''
    mkdir -p $out
    cp ${config} $out/config.yaml
  '';
in
symlinkJoin {
  name = "beets";
  paths = [
    (pkgs.python3.pkgs.beets.override {
      pluginOverrides = {
        fetchartist = {
          enable = true;
          propagatedBuildInputs = [ (pkgs.callPackage ./beets-fetchartist.nix { }) ];
        };
      };
    })
  ];

  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/beet --set BEETSDIR ${configDir}
  '';
}
