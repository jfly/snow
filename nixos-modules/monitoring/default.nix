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
    expose = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to expose metrics on this host and configure our Prometheus
        instance to scrape those metrics.
      '';
    };
    nodeTextfileDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/prometheus-node-exporter-text-files";
    };
  };

  config = lib.mkIf cfg.expose {
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
