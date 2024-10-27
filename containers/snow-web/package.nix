{ pkgs }:
let
  nginx = pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

  nginxConf =
    pkgs.runCommand "nginx-conf"
      {
        webroot = ./webroot;
        inherit nginx;
      }
      ''
        cp -r ${./conf} $out

        # This env var is referenced by the nginx conf files we're about to
        # run substitution on.
        export nginxConf=$out

        shopt -s globstar
        for f in $out/**/*.conf; do
          substituteAllInPlace $f
        done
      '';

  snow-web = pkgs.writeShellScriptBin "snow-web" ''
    exec ${nginx}/bin/nginx -e /dev/stderr -c ${nginxConf}/nginx.conf
  '';
in
pkgs.dockerTools.streamLayeredImage {
  name = "snow-web";

  contents = [ pkgs.fakeNss ];

  extraCommands = ''
    mkdir -p tmp/nginx_client_body
  '';

  config = {
    Cmd = [ "${snow-web}/bin/snow-web" ];
    ExposedPorts = {
      "80" = { };
    };
  };
}
