{
  config,
  lib,
  ...
}:

let
  cfg = config.snow.monitoring;
in
{
  options.snow.monitoring = {
    alertIfDown = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to alert if this host is down. Disable for any devices that
        are not expected to be online all the time.
      '';
    };
    nodeTextfileDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/prometheus-node-exporter-text-files";
    };
  };

  config = {
    assertions = [
      {
        assertion = config.networking.domain != null;
        message = ''
          Monitoring requires that `config.networking.domain` is set, so
          Prometheus can scrape metrics.
        '';
      }
    ];

    system.activationScripts.node-exporter-text-files-dir = ''
      mkdir --parents --mode 0777 ${cfg.nodeTextfileDir}
    '';

    # Keep the list of exporters in sync with `scrapeConfigs` in `hosts/fflewddur/prometheus.nix`.
    services.prometheus.exporters = {
      node = {
        enable = true;
        port = 9000;
        openFirewall = true;
        enabledCollectors = [ "systemd" ];
        extraFlags = [
          "--collector.textfile.directory=${cfg.nodeTextfileDir}"
        ];
      };
    };
  };
}
