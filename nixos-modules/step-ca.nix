{
  lib,
  config,
  pkgs,
  ...
}:

let
  # Only allow the CA to generate certs for these domains. That way, even if
  # the CA key is leaked, attackers can't MITM "real" websites. More
  # realistically, it means I cannot snoop on my spouse's web traffic, which is
  # a good thing.
  permittedDnsDomains = [ "snow" ];

  domain = {
    sld = "ca";
    # This domain is handled by nginx (other servers will use this to generate certs).
    fqdn = "ca.snow";
    # This local domain is specifically for step-ca, which needs to run over
    # https with a domain name it can generate a cert for. The CA is not
    # allowed to generate certs for `localhost`, so we need some other domain
    # that resolves to localhost instead.
    local = "local.ca.snow";
  };

  cfg = config.snow.step-ca;
in
{
  options.snow.step-ca = {
    role = lib.mkOption {
      type = lib.types.enum [
        "client"
        "server"
      ];
    };
  };

  config = {
    # Trust certs from our self-hosted CA.
    # See `machines/fflewddur/step-ca.nix` for details.
    security.pki.certificateFiles = [
      config.clan.core.vars.generators.step-root-ca.files."ca.crt".path
    ];

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "jeremyfleischman@gmail.com";
        server =
          if cfg.role == "server" then
            "https://${domain.local}:${toString config.services.step-ca.port}/acme/acme/directory"
          else if cfg.role == "client" then
            "https://${domain.fqdn}/acme/acme/directory"
          else
            throw "Unrecognized role ${cfg.role}";
      };
    };

    clan.core.vars.generators.step-root-ca = {
      share = true;

      files."ca.key" = {
        secret = true;
        deploy = false;
      };
      files."ca.crt".secret = false;
      runtimeInputs = [ pkgs.step-cli ];
      script = ''
        step certificate create \
          --template ${pkgs.writeText "root.tmpl" ''
            {
              "subject": {{ toJson .Subject }},
              "issuer": {{ toJson .Subject }},
              "keyUsage": ["certSign", "crlSign"],
              "basicConstraints": {
                "isCA": true,
                "maxPathLen": 1
              },
              "nameConstraints": {
                "critical": true,
                "permittedDNSDomains": ${builtins.toJSON permittedDnsDomains}
              }
            }
          ''} \
          --no-password --insecure \
          "Snow Root CA" $out/ca.crt $out/ca.key
      '';
    };
  };

  imports = [
    {
      config = lib.mkIf (cfg.role == "server") {
        networking.extraHosts = "127.0.0.1 ${domain.local}";

        services.data-mesher.settings.host.names = [ domain.sld ];
        services.nginx.virtualHosts.${domain.fqdn} = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "https://localhost:${toString config.services.step-ca.port}";
          };
        };

        clan.core.vars.generators.step-intermediate-ca = {
          files."intermediate.key" = {
            secret = true;
            deploy = true;
          };
          files."intermediate.crt".secret = false;
          dependencies = [ "step-root-ca" ];
          runtimeInputs = [ pkgs.step-cli ];
          script = ''
            step certificate create \
              --profile intermediate-ca \
              --ca $in/step-root-ca/ca.crt \
              --ca-key $in/step-root-ca/ca.key \
              --no-password --insecure \
              "Snow Intermediate CA" $out/intermediate.crt $out/intermediate.key
          '';
        };

        systemd.services.step-ca.serviceConfig.LoadCredential = [
          "intermediate_key:${
            config.clan.core.vars.generators.step-intermediate-ca.files."intermediate.key".path
          }"
        ];
        services.step-ca = {
          enable = true;
          address = "127.0.0.1";
          port = 8443;
          intermediatePasswordFile = "/dev/null";
          settings = {
            root = config.clan.core.vars.generators.step-root-ca.files."ca.crt".path;
            crt = config.clan.core.vars.generators.step-intermediate-ca.files."intermediate.crt".path;
            # Ideally this would be a reference to $CREDENTIALS_DIRECTORY. See
            # https://systemd.io/CREDENTIALS/#relevant-paths
            key = "/run/credentials/step-ca.service/intermediate_key";
            # This machine is the only thing that talks directly to step-ca.
            # Everything else is proxied through nginx.
            dnsNames = [ domain.local ];
            # You need to configure a db for ACME to work. If you don't, you'll just
            # get a 404 with no additional information :(
            db = {
              type = "badger";
              dataSource = "/var/lib/step-ca/db";
            };
            authority = {
              provisioners = [
                {
                  type = "ACME";
                  name = "acme";
                }
              ];
            };
          };
        };
      };
    }
  ];
}
