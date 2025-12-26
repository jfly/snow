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
        job_name = "smartctl";
        static_configs =
          let
            targets = lib.pipe flake.nixosConfigurations [
              # Get just the `config`s.
              (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
              # Filter to hosts that have the `smartctl` exporter enabled.
              (builtins.filter (config: config.services.prometheus.exporters.smartctl.enable))
              (lib.groupBy (
                config: if config.snow.monitoring.alertIfDown then "alertIfDown" else "noAlertIfDown"
              ))
              # For each host, produce a target such as "clark.ec:9000".
              (lib.mapAttrs (
                _: configs:
                map (
                  config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.smartctl.port}"
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
      (pkgs.writeText "smartctl-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "smartctl";
              rules =
                map
                  (name: {
                    alert = "${name} greater than 0";
                    expr = ''
                      smartctl_device_attribute{attribute_value_type="raw", attribute_name="${name}"} > 0
                    '';
                    for = "5m";
                    labels.severity = "error";
                    annotations.summary = "Drive {{ $labels.name }} on {{ $labels.instance }} has nonzero ${name}. This may be a sign of pending drive failure. See <https://www.snapraid.it/faq#smart> for details.";
                  })
                  [
                    # List of SMART attributes from <https://www.snapraid.it/faq#smart>.
                    "Reallocated_Sector_Ct"
                    "Reported_Uncorrect"
                    # Only one of our drives reports this metric, and it reports
                    # it as 3 values packed into one, which Prometheus doesn't
                    # understand. See
                    # <https://www.disktuna.com/big-scary-raw-s-m-a-r-t-values-arent-always-bad-news/>
                    # for details.
                    # According to <https://www.snapraid.it/faq#smart>, this is
                    # not a metric that Google suggested monitoring for replacing
                    # disks.
                    # "Command_Timeout"
                    "Current_Pending_Sector"
                    "Offline_Uncorrectable"
                  ];
            }
          ];
        }
      ))
    ];
  };
}
