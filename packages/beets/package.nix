{
  pkgs,
  formats,
  makeWrapper,
  runCommand,
  symlinkJoin,
}:

let
  beetsConfig = {
    # TODO: I had to manually run `mkdir -p /root/.local/state/beet/` before this would work.
    statefile = "/root/.local/state/beet/state.pickle";

    plugins = [
      "musicbrainz"
      "badfiles"
      "duplicates"
      "embedart"
      "fetchart"
      "fetchartist"
      "mbsync"
      "missing"
      "unimported"
      "convert"
    ];

    directory = "/mnt/media/music/jfly";
    library = "/mnt/media/music/jfly/beets.db";
    unimported = {
      ignore_extensions = "db jpg";
      ignore_subdirectories = "";
    };

    # I only use this plugin in order to remove embedded album art.
    embedart = {
      auto = "no";
    };

    fetchart = {
      auto = "yes";
      sources = "filesystem coverart itunes amazon albumart";
    };

    fetchartist = {
      # This is for compatibility with Navidrome: https://github.com/navidrome/navidrome/issues/394
      filename = "artist";
    };

    badfiles = {
      # Hacks to avoid dependencies on noisy third party checkers such as
      # https://aur.archlinux.org/packages/mp3val/). For now I'm just
      # interested in finding files that are in the database but not on the
      # filesystem.
      commands = {
        mp3 = "echo good";
        wma = "echo good";
        m4a = "echo good";
        flac = "echo good";
      };
    };
  };
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
