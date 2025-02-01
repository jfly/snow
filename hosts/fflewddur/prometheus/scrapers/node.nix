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
                      round((node_filesystem_free_bytes{${diskSelector}} * 100) / node_filesystem_size_bytes{${diskSelector}}) < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                  }
                  # TODO: this rule is quite specific. Should we instead
                  #       express it somewhere node-specific (and absorb those rules
                  #       here)? Maybe talk to the clan folks to see if they've
                  #       thought about this at all?
                  # `/mnt/bay` is quite large, we have slightly different rules for it.
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
                      round((node_filesystem_free_bytes{mountpoint="/mnt/bay"} * 100) / node_filesystem_size_bytes{mountpoint="/mnt/bay"}) < 5
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                  }
                ];
            }
          ];
        }
      ))
    ];
  };
}
