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
        job_name = "zrepl";
        static_configs =
          let
            targets = lib.pipe flake.nixosConfigurations [
              # Get just the `config`s.
              (lib.mapAttrsToList (_name: nixosConfiguration: nixosConfiguration.config))
              # Filter to hosts that have `zrepl` enabled.
              (builtins.filter (config: config.services.zrepl.enable))
              (lib.groupBy (
                config: if config.snow.monitoring.alertIfDown then "alertIfDown" else "noAlertIfDown"
              ))
              # For each host, produce a target such as "clark.ec:9811".
              (lib.mapAttrs (_: configs: map (config: "${config.networking.fqdn}:9811") configs))
            ];
          in
          [
            {
              targets = targets.alertIfDown or [ ];
              labels.alert_if_down = "true";
            }
            {
              targets = targets.noAlertIfDown or [ ];
              labels.alert_if_down = "false";
            }
          ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "zrepl.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "zrepl";
              rules = [
                {
                  alert = "ZreplLongTimeNoSuccess";
                  expr = ''
                    time() - zrepl_replication_last_successful > ${toString (2 * 24 * 60 * 60)}
                  '';
                  for = "30m";
                  labels.severity = "error";
                  annotations.summary = "zrepl job {{ $labels.zrepl_job }} has not succeeded recently.";
                }
              ]
              ++ (
                # Having an explicit list of jobs is useful so we get alerted
                # even if the job's metrics completely disappear.
                let
                  criticalJobs = [
                    "bay_to_baykup"
                  ];
                in
                map (criticalJob: {
                  alert = "ZreplJobMissing-${criticalJob}";
                  expr = ''
                    absent(zrepl_replication_last_successful{zrepl_job="${criticalJob}"})
                  '';
                  for = "30m";
                  labels.severity = "error";
                  annotations.summary = "zrepl job ${criticalJob} is missing";
                }) criticalJobs
              );
            }
          ];
        }
      ))
    ];
  };
}
