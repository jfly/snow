{
  config,
  ...
}:
{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.port}" ];
            labels.alert_if_down = "true";
          }
        ];
      }
    ];
  };
}
