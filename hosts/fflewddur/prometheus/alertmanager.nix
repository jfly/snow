# TODO: get rid of Uptime Karma
{ config, ... }:

let
  sendgridApiKeyId = "sendgrid-api-key-id";
  zendutyWebhookUrlId = "zenduty-webhook-url-id";
  healthchecksWebhookUrlId = "healthchecks-webhook-url-id";
in
{
  # From https://www.zenduty.com/dashboard/teams/daf139eb-24a2-4991-a8c8-04e80e4f16e6/services/7fc79e41-f284-404f-8573-25bf37e62a4f/integrations/08df6240-794b-4885-a8c7-5e2446e4d13a/configure/
  age.secrets.zenduty-webhook-url.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBxODBkWDhnM3NQTzgwNzhs
    S29hVG9KL2lYWVJrY3BwT0ZxRTRnY2VDSG5FCmViV0RuTjI5VDNaZVFmcDNBVHln
    RVp0VmhpU1QwUERjN0JjVWNTQVBpSEkKLS0tIGRBa1JCRy9NY3hFd2g0cTNldGNR
    WUNtYVlYODBCY3NTUlkrV1ltWTFacVUKjjuz30xP1N9hQ2li9Qpv4pkKzMVbjrGi
    5u8CkF0584FKOqNejIrkMwh9KBqUw6JHts9OpXjFZg19rWyNLjQNC35BFr6QyfIz
    BdwG4RTKssmTdIQdPRN42U1x6VL+O2oxruEKL/IDMX+mWl68MEqUt135HXifnNbc
    SAK6wFA=
    -----END AGE ENCRYPTED FILE-----
  '';

  # From https://app.sendgrid.com/settings/api_keys
  age.secrets.sendgrid-api-key.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA3dTRTRmw0WW1Xbk9USlFN
    SmYvNHZ4M1FMaVY3bXVHdjhmSDF0OTVYR2lzCnZxUDVkNU51bzBWWjZiTXZENDBF
    OExqZ05IOThpQmREaDV2VlJKRlFXSGsKLS0tIG1lRDY2THZ5QnNkNVVldXpuV3gy
    MnhsVnNvM0ZIQzFPd3pHOXgyWlViRGMKXheqw9YpB2P32nCZiSj4UOMAXourfapX
    jXo8ZR8w1wqKxMOCd4OjGqXDCO40IiJgExxNUhvXe34bMMe7sn8zfes/puZru2cd
    k9+N5qixSS+ykgV7puzEql/RYSq4lVmgS7WdpS8=
    -----END AGE ENCRYPTED FILE-----
  '';

  # From https://healthchecks.io/projects/652f2de0-ceb3-41af-97c4-b3ecb96b5cc3/checks/
  age.secrets.heathchecks-io-prometheus.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBlZGR6ZGdIb0J1NCtsb28r
    QjlVbE9nYXo2dlRLQ05Qcys0M2krY1dkeFFjCjVKRWowekJMazZMYzJlM1IwN1ow
    cW4vaFVoSkpTSmdIeW5BTllWYTBsWEkKLS0tIFBsUnRKMzZ4VVc0Vm5BTDZrYmda
    OG1yZTlQZ1dHbTNyTlJyWFc4emJxNEkKxA+eLhBi6uInCOX7YWSj8QQg9bNZJ6wZ
    6TDFtO97WkqAhtDqEIEotsatKhUXr6bJXXYZtXQX/Nv8l8AWrID2q/RY6EKrUf7t
    /1KSVkYHHGX/W51ixcUPQA==
    -----END AGE ENCRYPTED FILE-----
  '';

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "${sendgridApiKeyId}:${config.age.secrets.sendgrid-api-key.path}"
    "${zendutyWebhookUrlId}:${config.age.secrets.zenduty-webhook-url.path}"
    "${healthchecksWebhookUrlId}:${config.age.secrets.heathchecks-io-prometheus.path}"
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
      webExternalUrl = "https://alerts.snow.jflei.com";

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

  services.nginx = {
    enable = true;
    virtualHosts."alerts.snow.jflei.com" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
      };
    };
  };
}
