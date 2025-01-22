{
  flake,
  config,
  lib,
  ...
}:

{
  services.prometheus = {
    enable = true;
    # Keep `scrapeConfigs` in sync with the exporters enabled in
    # `nixos-modules/monitoring/default.nix`.
    scrapeConfigs = [
      {
        job_name = "node";
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
  };

  services.nginx = {
    enable = true;
    virtualHosts."prometheus.snow.jflei.com" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
      };
    };
  };
}
