{ config, ... }:

let
  inherit (config.snow) services;

  sendgridApiKeyId = "sendgrid-api-key-id";
  zendutyWebhookUrlId = "zenduty-webhook-url-id";
  healthchecksWebhookUrlId = "healthchecks-webhook-url-id";
in
{
  clan.core.vars.generators.zenduty-webhook = {
    prompts.url = {
      description = "From https://www.zenduty.com/dashboard/teams/daf139eb-24a2-4991-a8c8-04e80e4f16e6/services/7fc79e41-f284-404f-8573-25bf37e62a4f/integrations/08df6240-794b-4885-a8c7-5e2446e4d13a/configure/";
      persist = true;
    };
  };

  clan.core.vars.generators.sendgrid-api = {
    prompts.key = {
      description = "From https://app.sendgrid.com/settings/api_keys";
      persist = true;
    };
  };

  clan.core.vars.generators.heathchecks-io-prometheus = {
    prompts.url = {
      description = "From https://healthchecks.io/projects/652f2de0-ceb3-41af-97c4-b3ecb96b5cc3/checks/";
      persist = true;
    };
  };

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "${sendgridApiKeyId}:${config.clan.core.vars.generators.sendgrid-api.files."key".path}"
    "${zendutyWebhookUrlId}:${config.clan.core.vars.generators.zenduty-webhook.files."url".path}"
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
      webExternalUrl = services.alerts.base_url;

      configuration = {
        global = {
          smtp_from = "prometheus@snowdon.jflei.com";
          smtp_smarthost = "smtp.sendgrid.net:587";
          smtp_auth_username = "apikey";
          smtp_auth_password_file = "$CREDENTIALS_DIRECTORY/${sendgridApiKeyId}";
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
                url_file = "$CREDENTIALS_DIRECTORY/${zendutyWebhookUrlId}";
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

  services.data-mesher.settings.host.names = [ services.alerts.sld ];
  services.nginx.virtualHosts.${services.alerts.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
    };
  };
}
