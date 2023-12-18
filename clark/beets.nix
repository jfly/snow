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
  paths = [
    # TODO: re-enable regular beets once https://github.com/NixOS/nixpkgs/issues/273907 is fixed
    # beets
    (beets.override { pluginOverrides = { replaygain.enable = false; }; })
  ];

  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/beet --set BEETSDIR ${configDir}
  '';
}
