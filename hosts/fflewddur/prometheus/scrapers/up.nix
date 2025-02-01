{
  flake,
  lib,
  pkgs,
  ...
}:
{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "up";
        static_configs = [
          {
            targets = lib.pipe flake.nixosConfigurations [
              # Get just the `config`s.
              (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
              # Filter to hosts that have the `node` exporter enabled.
              (builtins.filter (config: config.services.prometheus.exporters.node.enable))
              # For each host, produce a target such as "clark.ec:9000".
              (map (
                config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}"
              ))
            ];
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "up.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "up";
              rules = [
                {
                  alert = "NotUp";
                  expr = ''
                    up == 0
                  '';
                  for = "10m";
                  labels.severity = "warning";
                  annotations.summary = "scrape job {{ $labels.job }} is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
