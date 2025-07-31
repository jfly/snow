{
  config,
  lib,
  pkgs,
  ...
}:
let
  pathType = lib.types.strMatching "^\/.*";
  oauth2Services = lib.filterAttrs (name: service: service.oauth2 != null) config.snow.services;
in
{
  options.snow.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        local@{ name, ... }:
        {
          options = {
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
            base_url = lib.mkOption {
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
                  "${local.config.base_url}${pathOrFunc}"
                else
                  attrs: "${local.config.base_url}${pathOrFunc attrs}"
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
    snow.services = {
      audiobookshelf = { };
      budget = {
        oauth2 = {
          groups.access = "budget_access";
        };
        # https://oauth2-proxy.github.io/oauth2-proxy/features/endpoints
        paths.oauth2Callback = "/oauth2/callback";
      };
      ca = { };
      home-assistant = { };
      immich = { };
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
      mqtt.scheme = "mqtts";
      nextcloud = { };
      ospi = { };
      podhacks = { };
      step-ca.sld = "ca";
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
    ) oauth2Services;
  };
}
