{
  description = "speedtest-go";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages = rec {
          speedtest-go = pkgs.callPackage ./package.nix { };

          stream-docker = pkgs.dockerTools.streamLayeredImage {
            name = "speedtest-go";

            config = {
              Cmd = [ "${packages.speedtest-go}/bin/speedtest" ];
              ExposedPorts = {
                "8989" = { };
              };
            };
          };
          default = speedtest-go;
        };
        apps = rec {
          default = {
            type = "app";
            program = "${packages.speedtest-go}/bin/speedtest";
          };
          stream-docker = {
            type = "app";
            program = "${packages.stream-docker}";
          };
        };
      }
    );
}
