{
  flake,
  config,
  lib,
  pkgs,
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

    ruleFiles =
      let
        diskSelector = ''mountpoint="/"'';
      in
      [
        (pkgs.writeText "node-exporter.rules" (
          builtins.toJSON {
            groups = [
              {
                name = "node";
                rules = [
                  {
                    alert = "PartitionLowInodes";
                    expr = ''
                      node_filesystem_files_free / node_filesystem_files{${diskSelector}} * 100 < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has only {{ $value }}% free inodes.";
                  }
                  {
                    alert = "PartitionLowDiskSpace";
                    expr = ''
                      round((node_filesystem_free_bytes{${diskSelector}} * 100) / node_filesystem_size_bytes{mountpoint="/"}) < 10
                    '';
                    for = "30m";
                    labels.severity = "warning";
                    annotations.summary = "{{ $labels.device }} mounted to {{ $labels.mountpoint }} ({{ $labels.fstype }}) on {{ $labels.instance }} has {{ $value }}% free.";
                  }
                  {
                    alert = "SystemdUnitFailed";
                    expr = ''
                      node_systemd_unit_state{state="failed"} == 1
                    '';
                    for = "15m";
                    labels.severity = "warning";
                    annotations.summary = "systemd unit {{ $labels.name }} on {{ $labels.instance }} has been down for more than 15 minutes.";
                  }
                ];
              }
            ];
          }
        ))
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
