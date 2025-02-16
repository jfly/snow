{ config, pkgs, ... }:

let
  mkStaticProbe =
    {
      module,
      targets,
      job_suffix ? "",
    }:
    {
      job_name = "blackbox-${module}${job_suffix}";
      metrics_path = "/probe";
      params = {
        module = [ module ];
      };
      static_configs = [ { inherit targets; } ];
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          # <<< replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
          replacement = "mail.playground.jflei.com:${toString config.services.prometheus.exporters.blackbox.port}";
        }
      ];
    };

  mkDnsSdProbe = module: dns_sd_config: {
    job_name = "blackbox-${module}";
    metrics_path = "/probe";
    params = {
      module = [ module ];
    };
    dns_sd_configs = [
      dns_sd_config
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
  };
in
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
                { expect = "^220"; }
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
      # TODO: remove this static probe once `umbriel` is our MX record, and
      # ImprovMX is out of the picture.
      # https://github.com/NixOS/infra/issues/485
      (mkStaticProbe {
        module = "smtp_starttls";
        job_suffix = "_umbriel";
        targets = [ "umbriel.nixos.org:25" ];
      })
      (mkDnsSdProbe "smtp_starttls" {
        names = [
          "playground.jflei.com"
          "nixos.org"
        ];
        type = "MX";
        port = 25;
      })
    ];
  };
}
