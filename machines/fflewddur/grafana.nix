{ pkgs, config, ... }:
let
  inherit (config.snow) services;
in
{
  clan.core.vars.generators.grafana = {
    files."secret_key" = { };
    runtimeInputs = with pkgs; [
      openssl
    ];
    script = ''
      openssl rand -hex 32 > $out/secret_key
    '';
  };

  systemd.services.vaultwarden.serviceConfig = {
    LoadCredential = [
      "secret_key:${config.clan.core.vars.generators.grafana.files.secret_key.path}"
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3100;
        enforce_domain = true;
        domain = services.grafana.fqdn;
      };
      # Ideally this would be a reference to $CREDENTIALS_DIRECTORY. See
      # <https://systemd.io/CREDENTIALS/#relevant-paths>. However, grafana
      # doesn't support references to both env vars and files at the same time, see
      # <https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#variable-expansion>
      security.secret_key = "$_file{/run/credentials/${config.systemd.services.grafana.name}/secret_key}";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
        }
      ];
    };
  };

  snow.services.grafana.proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";

  snow.backup.paths = [ config.services.grafana.dataDir ];
}
