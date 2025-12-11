{
  config,
  lib,
  pkgs,
  ...
}:
let
  pathType = lib.types.strMatching "^\/.*";
  oauth2ServiceNeedingClientSecretGenerator = lib.filterAttrs (
    name: service: service.oauth2.generateClientSecret or false
  ) config.snow.services;
  servicesOnThisMachine = lib.attrValues (
    lib.filterAttrs (name: service: service.hostedHere) config.snow.services
  );
  regenerateCommand = "To fix: nix run .#gen-hosts > nixos-modules/shared/host-to-services.toml";
in
{
  options.snow.generateAllOauth2ClientSecrets = lib.mkEnableOption ''
    Whether to declare a generator for all OAuth2 client secrets.
    Only enable this on the machine hosting the OAuth provider (Kanidm).
  '';

  options.snow.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        local@{ name, ... }:
        {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default =
                let
                  hostToServicesFile = ./host-to-services.toml;
                  hostToServices = builtins.fromTOML (builtins.readFile hostToServicesFile);
                  serviceToHost = lib.listToAttrs (
                    lib.flatten (
                      lib.mapAttrsToList (host: fqdns: map (fqdn: lib.nameValuePair fqdn host) fqdns) hostToServices
                    )
                  );
                  hostOfRecord =
                    serviceToHost.${local.config.fqdn}
                      or (throw "${local.config.fqdn} missing from ${hostToServicesFile}.\n\n${regenerateCommand}");
                  # If we're hosting this service, but the host of record is
                  # different than us -> uh oh!
                  isIpWrong = local.config.hostedHere && config.networking.hostName != hostOfRecord;
                in
                assert lib.assertMsg (!isIpWrong)
                  "Incorrect host of record for ${local.config.fqdn} in ${hostToServicesFile}! Expected: ${config.networking.hostName}, got: ${hostOfRecord}\n\n${regenerateCommand}";
                hostOfRecord;
            };
            hostedHere = lib.mkOption {
              type = lib.types.bool;
              default = local.config.proxyPass != null;
            };
            proxyPass = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            nginxExtraConfig = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
            };

            sld = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            tld = lib.mkOption {
              type = lib.types.str;
              default = config.snow.tld;
            };
            fqdn = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${local.config.sld}.${local.config.tld}";
            };
            scheme = lib.mkOption {
              type = lib.types.str;
              default = "https";
            };
            baseUrl = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${local.config.scheme}://${local.config.fqdn}";
            };
            paths = lib.mkOption {
              type = lib.types.attrsOf (lib.types.either (lib.types.functionTo pathType) pathType);
              default = { };
            };
            urls = lib.mkOption {
              type = lib.types.attrsOf (lib.types.either (lib.types.functionTo lib.types.str) lib.types.str);
              readOnly = true;
              default = lib.mapAttrs (
                _name: pathOrFunc:
                if lib.isString pathOrFunc then
                  "${local.config.baseUrl}${pathOrFunc}"
                else
                  attrs: "${local.config.baseUrl}${pathOrFunc attrs}"
              ) local.config.paths;
            };
            oauth2 = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options = {
                    clientId = lib.mkOption {
                      type = lib.types.str;
                      default = name;
                    };
                    clientSecretPath = lib.mkOption {
                      type = lib.types.pathWith {
                        inStore = false;
                        absolute = true;
                      };
                      readOnly = true;
                      default = config.clan.core.vars.generators."kanidm-oauth2-${name}".files.basic-secret.path;
                    };
                    generateClientSecret = lib.mkOption {
                      type = lib.types.bool;
                      default = config.snow.generateAllOauth2ClientSecrets || local.config.hostedHere;
                      description = ''
                        Whether to generate the client secret.
                        Only enable this on machines that need it (usually the
                        machine that hosts the service and the machine that
                        hosts the OAuth provider: Kanidm).
                      '';
                    };
                    groups = lib.mkOption {
                      type = lib.types.attrsOf lib.types.str;
                      default = { };
                    };
                  };
                }
              );
              default = null;
            };
          };
        }
      )
    );
  };

  config = {
    services.data-mesher.settings.host.names = map (service: service.sld) servicesOnThisMachine;

    services.nginx.virtualHosts = lib.mkMerge (
      map (service: {
        ${service.fqdn} = {
          enableACME = true;
          forceSSL = true;

          locations."/" = {
            proxyPass = service.proxyPass;
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = lib.mkIf (service.nginxExtraConfig != null) service.nginxExtraConfig;
          };
        };
      }) servicesOnThisMachine
    );

    networking.extraHosts = lib.mkMerge (
      map (
        service:
        let
          ip = builtins.readFile ../../vars/per-machine/${service.host}/zerotier/zerotier-ip/value;
        in
        "${ip} ${service.fqdn}"
      ) (lib.attrValues config.snow.services)
    );

    snow.services = {
      alerts = { };
      audiobookshelf = { };
      bazarr = { };
      budget = {
        oauth2 = {
          groups.access = "budget_access";
        };
        # https://oauth2-proxy.github.io/oauth2-proxy/features/endpoints
        paths.oauth2Callback = "/oauth2/callback";
      };
      ca = { };
      frigate = { };
      grafana = { };
      home-assistant = { };
      immich = { };
      immichframe = { };
      jackett = { };
      jellyfin = { };
      kanidm = {
        sld = "auth";
        paths = {
          # https://kanidm.github.io/kanidm/master/integrations/oauth2.html#kanidms-oauth2-urls
          oauth2UserAuth = "/ui/oauth2";
          oauth2Token = "/oauth2/token";
          oauth2OidcUserinfo = { clientId }: "/oauth2/openid/${clientId}/userinfo";
          oauth2OidcIssuer = { clientId }: "/oauth2/openid/${clientId}";
        };
      };
      manman = { };
      media = { };
      miniflux = {
        oauth2 = {
          groups.access = "miniflux_access";
        };
        # https://miniflux.app/docs/howto.html#openid-connect
        paths.oauth2Callback = "/oauth2/oidc/callback";
      };
      mqtt.scheme = "mqtts";
      ospi = { };
      prometheus = { };
      radarr = { };
      readeck = { };
      seerr = { };
      sonarr = { };
      step-ca.sld = "ca";
      torrents = { };
      vaultwarden = { };
      whoami = {
        oauth2 = {
          groups.access = "whoami_access";
        };
        # https://oauth2-proxy.github.io/oauth2-proxy/features/endpoints
        paths.oauth2Callback = "/oauth2/callback";
      };
      zigbee2mqtt = { };
    };

    clan.core.vars.generators = lib.mapAttrs' (
      serviceName: service:
      lib.nameValuePair "kanidm-oauth2-${serviceName}" {
        share = true;
        files.basic-secret = { };
        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 48 1 | tr -d '\n' > $out/basic-secret
        '';
      }
    ) oauth2ServiceNeedingClientSecretGenerator;
  };
}
