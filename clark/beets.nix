{ beets
, formats
, makeWrapper
, runCommand
, symlinkJoin
, writeTextDir
, beetsConfig
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
  paths = [ beets ];

  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/beet --set BEETSDIR ${configDir}
  '';
}
