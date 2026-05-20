{
  config,
  inputs,
  pkgs,
  ...
}:
let
  monthInSeconds = 30 * 24 * 3600;
in
{
  imports = [ inputs.jnix.nixosModules.mullvad-stats ];

  clan.core.vars.generators.mullvad-accounts = {
    prompts."accounts" = {
      persist = true;
    };
  };

  services.mullvad-stats = {
    enable = true;
    accountNumbersFile = config.clan.core.vars.generators.mullvad-accounts.files.accounts.path;
  };

  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "mullvad";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.mullvad-stats.port}" ];
            labels.alert_if_down = "true";
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "mullvad.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "mullvad";
              rules = [
                {
                  alert = "MullvadTimeToRenew";
                  expr = ''
                    mullvad_expiry - time() < ${toString (2 * monthInSeconds)}
                  '';
                  for = "5m";
                  labels.severity = "warning";
                  annotations.summary = "It's time to renew Mullvad account {{$labels.account_name}}.";
                }
                {
                  alert = "MullvadExpired";
                  expr = ''
                    mullvad_expiry - time() < 0
                  '';
                  for = "5m";
                  labels.severity = "error";
                  annotations.summary = "Mullvad account {{$labels.account_name}} has expired.";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
