{
  description = "transmission with pirate-get";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = rec {
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
          stream-docker = pkgs.dockerTools.streamLayeredImage {
            name = "transmission";

            contents = [
              pkgs.dockerTools.caCertificates # needed by pirate-get
              my-pirate-get
            ];

            extraCommands = ''
              # transmission seems to want (need?) a /tmp directory
              mkdir -p tmp
            '';

            config = {
              Cmd = [ "${packages.my-transmission}/bin/transmission" ];
              ExposedPorts = {
                "9091" = { };
              };
            };
          };
          default = my-transmission;
        };
        apps = rec {
          default = {
            type = "app";
            program = "${packages.my-transmission}/bin/transmission";
          };
          stream-docker = {
            type = "app";
            program = "${packages.stream-docker}";
          };
        };
      }
    );
}
