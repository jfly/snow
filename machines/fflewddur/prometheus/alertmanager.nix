{ flake, config, ... }:

let
  inherit (config.snow) services;

  emailPasswordKeyId = "email-password-key-id";
  healthchecksWebhookUrlId = "healthchecks-webhook-url-id";
in
{
  imports = [
    flake.nixosModules.email-credentials-alerts
    ./ntfy-alertmanager.nix
  ];

  clan.core.vars.generators.heathchecks-io-prometheus = {
    prompts.url = {
      description = "From https://healthchecks.io/projects/652f2de0-ceb3-41af-97c4-b3ecb96b5cc3/checks/";
      persist = true;
    };
  };

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "${emailPasswordKeyId}:${config.clan.core.vars.generators.mail-alerts.files."password".path}"
    "${healthchecksWebhookUrlId}:${
      config.clan.core.vars.generators.heathchecks-io-prometheus.files."url".path
    }"
  ];

  services.prometheus = {
    alertmanagers = [
      {
        scheme = "http";
        static_configs = [
          { targets = [ "localhost:${toString config.services.prometheus.alertmanager.port}" ]; }
        ];
      }
    ];

    alertmanager = {
      enable = true;
      webExternalUrl = services.alerts.baseUrl;

      configuration = {
        global = {
          smtp_from = "alerts@playground.jflei.com";
          smtp_smarthost = "mail.playground.jflei.com:465";
          smtp_auth_username = "alerts@playground.jflei.com";
          smtp_force_implicit_tls = true;
          smtp_auth_password_file = "$CREDENTIALS_DIRECTORY/${emailPasswordKeyId}";
        };
        route = {
          receiver = "on-call";
          routes = [
            {
              receiver = "healthchecks.io-deadman";
              match.service = "deadman";
              repeat_interval = "5m";
            }
          ];
        };
        receivers = [
          {
            name = "on-call";
            email_configs = [
              {
                send_resolved = true;
                to = "jeremyfleischman@gmail.com";
              }
            ];
            webhook_configs = [
              {
                send_resolved = true;
                url = "http://127.0.0.1:${toString config.services.ntfy-alertmanager.port}";
              }
            ];
          }
          {
            name = "healthchecks.io-deadman";
            webhook_configs = [
              {
                url_file = "$CREDENTIALS_DIRECTORY/${healthchecksWebhookUrlId}";
              }
            ];
          }
        ];
      };
    };
  };

  snow.services.alerts.proxyPass = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
}
