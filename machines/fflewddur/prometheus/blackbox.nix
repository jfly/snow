{ config, pkgs, ... }:

let
  inherit (config.snow) services;

  fflewddurIp = builtins.readFile ../../../vars/per-machine/fflewddur/zerotier/zerotier-ip/value;

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
          replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
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
        replacement = "localhost:${toString config.services.prometheus.exporters.blackbox.port}";
      }
    ];
  };
in
{
  services.prometheus = {
    exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      configFile = pkgs.writeText "probes.yml" (
        builtins.toJSON {
          modules.https_success = {
            prober = "http";
            tcp.tls = true;
            http.headers.User-Agent = "blackbox-exporter";
          };

          modules.ipv6_https_success = {
            prober = "http";
            tcp.tls = true;
            http = {
              headers.User-Agent = "blackbox-exporter";
              # Try IPv6...
              preferred_ip_protocol = "ip6";
              # And do *not* fallback to IPv4.
              ip_protocol_fallback = false;
            };
          };

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

          modules.resolve_overlay_host = {
            prober = "dns";
            timeout = "5s";
            dns =
              let
                domainName = "home-assistant.m";
                expectedIp = fflewddurIp;
              in
              {
                query_type = "AAAA";
                query_name = domainName;
                preferred_ip_protocol = "ip4";
                validate_answer_rrs = {
                  fail_if_not_matches_regexp = [ ".*${expectedIp}" ];
                };
              };
          };
        }
      );
    };

    scrapeConfigs = [
      (mkDnsSdProbe "smtp_starttls" {
        names = [
          "playground.jflei.com"
        ];
        type = "MX";
        port = 25;
      })
      (mkStaticProbe {
        module = "https_success";
        targets = [
          services.manman.baseUrl
          services.media.baseUrl
          services.ospi.baseUrl
          "http://thermostat.ec/fan"
          "http://garage.ec/garage"
        ];
      })
      (mkStaticProbe {
        module = "ipv6_https_success";
        targets = [
          "https://www.jflei.com"
        ];
      })
      (mkStaticProbe {
        module = "resolve_overlay_host";
        targets = [
          fflewddurIp
        ];
      })
    ];

    ruleFiles = [
      (pkgs.writeText "blackbox-exporter.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "blackbox";
              rules = [
                {
                  alert = "CertificateExpiry";
                  # TODO: change this to something like 12 hours rather than 1.
                  # This requires changing the nixos acme module to specify a
                  # tighter `AccuracySec` (and perhaps `RandomizedDelaySec`)
                  # than it currently does. See
                  # <https://github.com/NixOS/nixpkgs/blob/ed269f843bb3577b84740f5a8e45a8080a1afdbe/nixos/modules/security/acme/default.nix#L361-L363>.
                  expr = ''
                    probe_ssl_earliest_cert_expiry - time() < 60 * 60 * 1
                  '';
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "Certificate for {{ $labels.instance }} is expiring soon.";
                }
                {
                  alert = "HttpUnreachable";
                  expr = ''
                    probe_success{job="blackbox-https_success"} == 0 or probe_success{job="blackbox-http_success"} == 0
                  '';
                  for = "15m";
                  labels.severity = "error";
                  annotations.summary = "Endpoint {{ $labels.instance }} is unreachable";
                }
                {
                  alert = "IPv6HttpUnreachable";
                  expr = ''
                    probe_success{job="blackbox-ipv6_https_success"} == 0
                  '';
                  for = "15m";
                  labels.severity = "error";
                  annotations.summary = "Endpoint {{ $labels.instance }} is unreachable over IPv6";
                }
                {
                  alert = "OverlayNetworkDnsDown";
                  expr = ''
                    probe_success{job="blackbox-resolve_overlay_host"} == 0
                  '';
                  for = "15m";
                  labels.severity = "error";
                  annotations.summary = "Overlay network DNS is down";
                }
                {
                  alert = "MxUnreachable";
                  expr = ''
                    probe_success{job="blackbox-smtp_starttls"} == 0
                  '';
                  for = "15m";
                  labels.severity = "error";
                  annotations.summary = "Mail server {{ $labels.instance }} is unreachable";
                }
                {
                  alert = "ThermostatUnreachable";
                  expr = ''
                    probe_success{job="blackbox-https_success", instance="http://thermostat.ec/fan"} == 0
                  '';
                  for = "5m";
                  labels.severity = "urgent";
                  annotations.summary = "The thermostat {{ $labels.instance }} is unreachable";
                }
              ];
            }
          ];
        }
      ))
    ];
  };
}
