{ pkgs }:
let
  my-transmission = pkgs.writeShellScriptBin "transmission" ''
    exec ${pkgs.transmission_4}/bin/transmission-daemon --foreground --log-level=info --config-dir ${./config-transmission}
  '';

  my-pirate-get =
    let
      config-pirate-get = pkgs.writeTextDir ".config/pirate-get" ''
        [Misc]
        openCommand = ${pkgs.transmission_4}/bin/transmission-remote -a %s
      '';
    in
    pkgs.writeShellScriptBin "pirate-get" ''
      export XDG_CONFIG_HOME=${config-pirate-get}/.config
      exec ${pkgs.pirate-get}/bin/pirate-get "$@"
    '';
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
