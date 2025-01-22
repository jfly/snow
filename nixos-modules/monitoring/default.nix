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

    # Keep the list of exporters in sync with `scrapeConfigs` in `hosts/fflewddur/prometheus.nix`.
    services.prometheus.exporters = {
      node = {
        enable = true;
        port = 9000;
      };
    };
  };
}
