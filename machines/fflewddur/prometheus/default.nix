{ pkgs, config, ... }:
let
  inherit (config.snow) services;
in
{
  imports = [
    ./alertmanager.nix
    # Keep the set of scrapers in sync with the exporters enabled in
    # `nixos-modules/monitoring/default.nix`.
    ./scrapers/up.nix
    ./scrapers/node.nix
    ./scrapers/smartctl.nix
    # Blackbox is unique: we run the exporter and the corresponding scraper on
    # only this node.
    ./blackbox.nix
    # mqtt-exporter is also unique: we run the exporter and the corresponding
    # scraper on only this node.
    ./mqtt-exporter.nix
    # Prometheus is also unique: there's only one node running Prometheus.
    ./scrapers/prometheus.nix
  ];

  services.prometheus = {
    enable = true;
    extraFlags = [
      # "--web.enable-admin-api"
    ];
    webExternalUrl = services.prometheus.baseUrl;
    retentionTime = "100y";

    # Set up a dead man's switch to monitor Prometheus itself.
    # Modeled after this blog post:
    # <https://jakubstransky.com/2019/01/26/who-monitors-prometheus/>.
    ruleFiles = [
      (pkgs.writeText "dead-man-switch.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "dead-man-switch";
              rules = [
                {
                  alert = "DeadManSwitch";
                  expr = "vector(1)";
                  labels.service = "deadman";
                  annotations.summary = "Alert that should always be firing (as a dead man's switch).";
                }
              ];
            }
          ];
        }
      ))
    ];
  };

  snow.services.prometheus.proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";

  snow.backup.paths = [ "/var/lib/${config.services.prometheus.stateDir}/data" ];
}
