{
  description = "snow web";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nginx = pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

        nginxConf = pkgs.runCommand "nginx-conf"
          {
            webroot = ./webroot;
            inherit nginx;
          } ''
          cp -r ${./conf} $out

          # This env var is referenced by the nginx conf files we're about to
          # run substitution on.
          export nginxConf=$out

          shopt -s globstar
          for f in $out/**/*.conf; do
            substituteAllInPlace $f
          done
        '';
      in
      rec {
        packages = rec {
          snow-web = pkgs.writeShellScriptBin "snow-web" ''
            exec ${nginx}/bin/nginx -e /dev/stderr -c ${nginxConf}/nginx.conf
          '';
          stream-docker = pkgs.dockerTools.streamLayeredImage {
            name = "snow-web";

            contents = [ pkgs.fakeNss ];

            extraCommands = ''
              mkdir -p tmp/nginx_client_body
            '';

            config = {
              Cmd = [ "${packages.snow-web}/bin/snow-web" ];
              ExposedPorts = {
                "80" = { };
              };
            };
          };
          default = snow-web;
        };
        apps = {
          default = {
            type = "app";
            program = "${packages.snow-web}/bin/snow-web";
          };
          stream-docker = {
            type = "app";
            program = "${packages.stream-docker}";
          };
        };
      }
    );
}
