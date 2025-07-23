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
        job_name = "node";
        static_configs =
          let
            targets = lib.pipe flake.nixosConfigurations [
              # Get just the `config`s.
              (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
              # Filter to hosts that have the `node` exporter enabled.
              (builtins.filter (config: config.services.prometheus.exporters.node.enable))
              (lib.groupBy (
                config: if config.snow.monitoring.alertIfDown then "alertIfDown" else "noAlertIfDown"
              ))
              # For each host, produce a target such as "clark.ec:9000".
              (lib.mapAttrs (
                _: configs:
                map (
                  config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}"
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
      (pkgs.writeText "node-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "node";
              rules =
                let
                  diskSelector = ''mountpoint="/"'';
                in
                [
                  {
                    alert = "SystemdUnitFailed";
                    expr = ''
                      node_systemd_unit_state{state="failed"} == 1
                    '';
                    for = "15m";
                    labels.severity = "error";
                    annotations.summary = "systemd unit {{ $labels.name }} on {{ $labels.instance }} has been down for more than 15 minutes.";
                  }

                  # Monitor root drive free space across the fleet.
                  {
                    alert = "PartitionLowInodes";
                    expr = ''
                      node_filesystem_files_free{${diskSelector}} / node_filesystem_files{${diskSelector}} * 100 < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has only {{ $value }}% free inodes.";
                  }
                  {
                    alert = "PartitionLowDiskSpace";
                    expr = ''
                      round((node_filesystem_avail_bytes{${diskSelector}} * 100) / node_filesystem_size_bytes{${diskSelector}}) < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                  }

                  # `/mnt/bay` is quite large, we have slightly different rules for it.
                  # TODO: These rules are pretty specific. Should we instead
                  #       express them somewhere node-specific (and absorb those rules
                  #       here)? Maybe talk to the clan folks to see if they've
                  #       thought about this at all?
                  {
                    alert = "BayPartitionLowInodes";
                    expr = ''
                      node_filesystem_files_free{mountpoint="/mnt/bay"} / node_filesystem_files{mountpoint="/mnt/bay"} * 100 < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has only {{ $value }}% free inodes.";
                  }
                  {
                    alert = "BayPartitionLowDiskSpace";
                    expr = ''
                      round((node_filesystem_avail_bytes{mountpoint="/mnt/bay"} * 100) / node_filesystem_size_bytes{mountpoint="/mnt/bay"}) < 5
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                  }

                  # Monitor Hetzner storage box free space.
                  {
                    alert = "HetznerStorageBoxLowDiskSpace";
                    expr = ''
                      round((hetzner_storage_box_avail_bytes * 100) / hetzner_storage_box_size_bytes) < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.filesystem }} mounted to {{ $labels.mountpoint }} has {{ $value }}% free.";
                  }

                ];
            }

            # TODO: I'm pretty sure this would be cleaner if expressed in a
            #       node-specific way. See comment above about talking to the
            #       clan folks.
            {
              name = "backups";
              rules =
                let
                  snowBackupRules = lib.pipe flake.nixosConfigurations [
                    # Get just the `config`s.
                    (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
                    # Filter to hosts that have paths to back up.
                    (builtins.filter (config: (config.snow.backup.paths != [ ])))
                    # For each host, produce an instance such as "clark.ec:9000".
                    (map (
                      config: "${config.networking.fqdn}:${toString config.services.prometheus.exporters.node.port}"
                    ))
                    (map (instance: {
                      alert = "SnowBackupFailed-${instance}";
                      expr = ''
                        (time() - backup_completion_timestamp_seconds{instance="${instance}"} > ${toString (2 * 24 * 60 * 60)})
                        or
                        absent(backup_completion_timestamp_seconds{instance="${instance}"})
                      '';
                      labels.severity = "error";
                      annotations.summary = "backup on {{ $labels.instance }} to site snow has not succeeded recently.";
                    }))
                  ];
                in
                snowBackupRules
                ++ [
                  {
                    alert = "HetznerBackupFailed";
                    expr = ''
                      (time() - backup_completion_timestamp_seconds{site="hetzner"} > ${toString (2 * 24 * 60 * 60)})
                      or
                      absent(backup_completion_timestamp_seconds{site="hetzner"})
                    '';
                    labels.severity = "error";
                    annotations.summary = "backup on {{ $labels.instance }} to site hetzner has not succeeded recently.";
                  }
                ];
            }
          ];
        }
      ))
    ];
  };
}
