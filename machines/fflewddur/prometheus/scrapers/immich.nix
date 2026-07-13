{
  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "immich";
        static_configs = [
          {
            targets = [
              "immich-metrics-api.m"
              "immich-metrics-microservices.m"
            ];
            labels.alert_if_down = "true";
          }
        ];
      }
    ];
  };
}
