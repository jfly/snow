{ config, pkgs, ... }:

{
  services.prometheus = {
    exporters.blackbox = {
      enable = true;
      # <<< listenAddress = "127.0.0.1";
      listenAddress = "0.0.0.0"; # <<<
      openFirewall = true; # <<<
      configFile = pkgs.writeText "probes.yml" (
        builtins.toJSON {
          # From https://github.com/prometheus/blackbox_exporter/blob/53e78c2b3535ecedfd072327885eeba2e9e51ea2/example.yml#L120-L133
          modules.smtp_starttls = {
            prober = "tcp";
            timeout = "5s";
            tcp = {
              query_response = [
                { expect = "^220 ([^ ]+) ESMTP (.+)$"; }
                { send = "EHLO prober\r"; }
                { expect = "^250-STARTTLS"; }
                { send = "STARTTLS\r"; }
                { expect = "^220"; }
                { starttls = true; }
                { send = "EHLO prober\r"; }
                { expect = "^250-AUTH"; }
                { send = "QUIT\r"; }
              ];
            };
          };
        }
      );
    };
    scrapeConfigs = [
      {
        job_name = "blackbox-smtp_starttls";
        metrics_path = "/probe";
        params = {
          module = [ "smtp_starttls" ];
        };
        dns_sd_configs = [
          {
            names = [
              "playground.jflei.com"
              "mail-test.nixos.org"
            ];
            type = "MX";
            port = 25;
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__address__" ];
            target_label = "host";
          }
          {
            source_labels = [ "__meta_dns_name" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            # <<< replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
            replacement = "mail.playground.jflei.com:${toString config.services.prometheus.exporters.blackbox.port}";
          }
        ];
      }
    ];
  };
}
