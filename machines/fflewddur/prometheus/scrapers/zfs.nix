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
        job_name = "zfs";
        static_configs =
          let
            targets = lib.pipe flake.nixosConfigurations [
              # Get just the `config`s.
              (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
              # Filter to hosts that have the `zfs` exporter enabled.
              (builtins.filter (config: config.services.prometheus.exporters.zfs.enable))
              (lib.groupBy (
                config: if config.snow.monitoring.alertIfDown then "alertIfDown" else "noAlertIfDown"
              ))
              # For each host, produce a target such as "clark.ec:9000".
              (lib.mapAttrs (
                _: configs:
                map (
                  config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.zfs.port}"
                ) configs
              ))
            ];
          in
          [
            {
              targets = targets.alertIfDown;
              labels.alert_if_down = "true";
            }
            {
              targets = targets.noAlertIfDown;
              labels.alert_if_down = "false";
            }
          ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "zfs.rules" (
        # TODO: alert on scrub fail, which AFAICT, is not exported to
        #       prometheus: <https://github.com/pdf/zfs_exporter/issues/20>
        builtins.toJSON {
          groups = [
            {
              name = "zfs";
              rules = [
                {
                  alert = "ZfsPoolFull";
                  expr = ''
                    (zfs_pool_free_bytes / zfs_pool_size_bytes) * 100 < 10
                  '';
                  for = "30m";
                  labels.severity = "warning";
                  annotations.summary = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} has only {{ $value }}% free space.";
                }
                {
                  alert = "ZfsPoolHealth";
                  expr = ''
                    zfs_pool_health > 0
                  '';
                  for = "5m";
                  labels.severity = "error";
                  annotations.summary = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} is unhealthy.";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
