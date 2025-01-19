{ pkgs }:
let
  my-transmission = pkgs.writeShellApplication {
    name = "transmission";
    runtimeInputs = [
      pkgs.coreutils # Provides `mkdir`.
      pkgs.transmission_4
    ];
    text = ''
      conf_dir=/root/.config/transmission
      mkdir -p "$conf_dir"
      cp ${./settings.json} "$conf_dir/settings.json"
      exec transmission-daemon --foreground --log-level=info --config-dir "$conf_dir"
    '';
  };

  my-pirate-get =
    let
      config-pirate-get = pkgs.writeTextDir ".config/pirate-get" ''
        [Misc]
        openCommand = ${pkgs.transmission_4}/bin/transmission-remote -a %s
      '';
    in
    pkgs.writeShellApplication {
      name = "pirate-get";
      text = ''
        export XDG_CONFIG_HOME=${config-pirate-get}/.config
        exec ${pkgs.pirate-get}/bin/pirate-get "$@"
      '';
    };
in
pkgs.dockerTools.streamLayeredImage {
  name = "transmission";

  contents = [
    pkgs.dockerTools.caCertificates # Needed by pirate-get
    my-pirate-get
  ];

  extraCommands = ''
    # transmission seems to want (need?) a /tmp directory
    mkdir -p tmp
  '';

  config = {
    Cmd = [ "${my-transmission}/bin/transmission" ];
    ExposedPorts = {
      "9091" = { };
    };
  };
}
