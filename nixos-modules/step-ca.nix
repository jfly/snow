{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (config.snow) services;

  domain = {
    tld = config.snow.tld;
    sld = services.step-ca.sld;
    # This domain is handled by nginx (other servers will use this to generate certs).
    fqdn = services.step-ca.fqdn;
    # This local domain is specifically for step-ca, which needs to run over
    # https with a domain name it can generate a cert for. The CA is not
    # allowed to generate certs for `localhost`, so we need some other domain
    # that resolves to localhost instead.
    local = "local.${domain.fqdn}";
  };

  # Only allow the CA to generate certs for these domains. That way, even if
  # the CA key is leaked, attackers can't MITM "real" websites. More
  # realistically, it means I cannot snoop on my spouse's web traffic, which is
  # a good thing.
  permittedDnsDomains = [ domain.tld ];

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

        # `step-ca` gives us certs that are valid for 1 day, so we need to renew
        # them frequently (the default for this is daily, which works fine with
        # Let's Encrypt's 90-day certs).
        renewInterval = "hourly";
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

      # `step-cli` has a `root-ca` profile [0] which makes this simpler, but we
      # want to add `nameConstraints`. That requires specifying a template,
      # which means we also need to be explicit about the certificate validity
      # (because `defaultTemplatevalidity` defaults to 1 day [1]).
      # [0]: https://github.com/smallstep/crypto/blob/v0.66.0/x509util/templates.go#L206-L214
      # [1]: https://github.com/smallstep/cli/blob/v0.28.6/command/certificate/create.go#L37
      script =
        let
          # https://github.com/smallstep/cli/blob/v0.28.6/command/certificate/create.go#L36
          rootValidityDuration = "${toString (10 * 365 * 24)}h";
        in
        ''
          step certificate create \
            --not-after ${rootValidityDuration} \
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
            "Manman Root CA" $out/ca.crt $out/ca.key
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
              "Manman Intermediate CA" $out/intermediate.crt $out/intermediate.key
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
