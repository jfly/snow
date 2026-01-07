# This module provides an extension to NixOS's nginx virtualHosts that allow
# protecting them behind an oauth2-proxy instance. NixOS already has support
# for oauth2-proxy and even an integration with nginx
# (services.oauth2-proxy.nginx), but I wrote all this code so I can run
# multiple oauth2-proxies. This allows for better integration with Kanidm.
# See "Why Does Sharing a Client Weaken OAuth2?" in
# https://kanidm.github.io/kanidm/master/integrations/oauth2/how_does_oauth2_work.html
#
# TODO: discuss with nixos maintainers if they'd be open to a refactor to
# `services.oauth2-proxy` and `services.oauth2-proxy.nginx` that would allow
# running multiple oauth2-proxies without containers.
{
  config,
  flake,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (config.snow) services;

  enabledVirtualHosts = lib.filterAttrs (
    name: virtualHost: virtualHost.snow.oauth2.enable
  ) config.services.nginx.virtualHosts;
  oauth2ProxiesDir = "/run/oauth2-proxies";
in
{
  # Copied (and modified) from
  # <https://github.com/oddlama/nix-config/blob/main/modules/oauth2-proxy.nix>
  # and
  # <https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/security/oauth2-proxy-nginx.nix>.
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options.snow.oauth2 = {
            enable = lib.mkEnableOption "access protection of this resource using oauth2-proxy.";
            allowedGroups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                A list of groups that are allowed to access this resource, or the
                empty list to allow any authenticated client.
              '';
            };
            X-User = lib.mkOption {
              type = lib.types.str;
              default = "$upstream_http_x_auth_request_preferred_username";
              description = "The variable to set as X-User";
            };
            X-Email = lib.mkOption {
              type = lib.types.str;
              default = "$upstream_http_x_auth_request_email";
              description = "The variable to set as X-User";
            };
            snowService = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              description = "A service from config.snow.services";
            };
          };
          options.locations = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (locationSubmod: {
                options.setOauth2Headers = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to add oauth2 specific headers to this location. Only takes effect is oauth2 is actually enabled on the parent vhost.";
                };
                config = lib.mkIf (config.snow.oauth2.enable && locationSubmod.config.setOauth2Headers) {
                  extraConfig = ''
                    proxy_set_header X-User  $user;
                    proxy_set_header X-Email $email;
                    add_header Set-Cookie $auth_cookie;
                  '';
                };
              })
            );
          };
          config = lib.mkIf config.snow.oauth2.enable {
            locations."/oauth2/" = {
              proxyPass = "http://unix:${oauth2ProxiesDir}/${name}.sock:";
              extraConfig = ''
                auth_request off;
                proxy_set_header X-Scheme                $scheme;
                proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
              '';
            };

            extraConfig = ''
              auth_request /oauth2/auth;
              error_page 401 = @redirectToAuth2ProxyLogin;

              # set variables that can be used in locations.<name>.extraConfig
              # pass information via X-User and X-Email headers to backend,
              # requires running with --set-xauthrequest flag
              auth_request_set $user  ${config.snow.oauth2.X-User};
              auth_request_set $email ${config.snow.oauth2.X-Email};
              # if you enabled --cookie-refresh, this is needed for it to work with auth_request
              auth_request_set $auth_cookie $upstream_http_set_cookie;
            '';

            locations."@redirectToAuth2ProxyLogin" = {
              setOauth2Headers = false;
              return = "307 /oauth2/start?rd=$scheme://$host$request_uri";
              extraConfig = ''
                auth_request off;
              '';
            };

            locations."= /oauth2/auth" = {
              setOauth2Headers = false;
              proxyPass =
                "http://unix:${oauth2ProxiesDir}/${name}.sock:/oauth2/auth"
                +
                  lib.optionalString (config.snow.oauth2.allowedGroups != [ ])
                    "?allowed_groups=${lib.concatStringsSep "," (map lib.escapeURL config.snow.oauth2.allowedGroups)}";
              extraConfig = ''
                auth_request off;
                internal;

                proxy_set_header X-Scheme       $scheme;
                # nginx auth_request includes headers but not body
                proxy_set_header Content-Length "";
                proxy_pass_request_body         off;
              '';
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (lib.length (lib.attrNames enabledVirtualHosts) > 0) {
    systemd.tmpfiles.settings."oauth2-proxies" = {
      ${oauth2ProxiesDir} = {
        d = {
          mode = "0777"; # Allow any user to read/write to the sockets in here.
          group = "root";
          user = "root";
        };
      };
    };

    clan.core.vars.generators = lib.mapAttrs' (
      virtualHostName: virtualHost:
      lib.nameValuePair "oauth2-cookie-${virtualHostName}" {
        files."secret" = { };
        runtimeInputs = [ pkgs.python3 ];
        script = ''
          python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())' | tr -d "\n" > $out/secret
        '';
      }
    ) enabledVirtualHosts;

    containers = lib.mapAttrs' (
      virtualHostName: virtualHost:
      let
        cookieSecretPath =
          config.clan.core.vars.generators."oauth2-cookie-${virtualHostName}".files.secret.path;
        snowService = virtualHost.snow.oauth2.snowService;
      in
      lib.nameValuePair "oauth2-proxy-${lib.replaceString "." "-" virtualHostName}" {
        autoStart = true;

        bindMounts.${snowService.oauth2.clientSecretPath}.isReadOnly = true;
        bindMounts.${cookieSecretPath}.isReadOnly = true;

        bindMounts.${oauth2ProxiesDir}.isReadOnly = false;

        # Needed by the nixos modules defined in this flake.
        specialArgs = {
          inherit inputs flake;
          outerConfig = config;
        };

        config = inner: {
          system.stateVersion = config.system.stateVersion;

          imports = [
            flake.nixosModules.nixos-container-networking
          ];

          # Generate an environment file for oauth2-proxy with the various
          # secrets it needs.
          # TODO: contribute `services.oauth2-proxy.clientSecretFile` and
          # `services.oauth2-proxy.cookieSecretFile` to nixpkgs?
          systemd.services."oauth2-proxy-setup-secrets" = {
            description = "Generate environment file for oauth2-proxy";
            requiredBy = [ "oauth2-proxy.service" ];
            partOf = [ "oauth2-proxy.service" ];
            before = [ "oauth2-proxy.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "oauth2-proxy-env-file-writer" ''
                set -euo pipefail

                env_file=/run/secrets/oauth2-proxy/env-file
                mkdir -p $(dirname "$env_file")
                : > "$env_file"

                # Generate the env file.
                echo "Generating oauth2-proxy env file: $env_file"
                echo "OAUTH2_PROXY_CLIENT_SECRET=$(< ${snowService.oauth2.clientSecretPath})" >> "$env_file"
                echo "OAUTH2_PROXY_COOKIE_SECRET=$(< ${cookieSecretPath})" >> "$env_file"
              '';
            };
          };

          # Copied from
          # <https://github.com/oddlama/nix-config/blob/7d4ce411c29652909cbf360cbf107837e7ee144c/modules/oauth2-proxy.nix#L154-L159>
          systemd.services.oauth2-proxy.serviceConfig = {
            RuntimeDirectory = "oauth2-proxy";
            RuntimeDirectoryMode = "0750";
            UMask = "001"; # TODO remove once https://github.com/oauth2-proxy/oauth2-proxy/issues/2141 is fixed
            RestartSec = "60"; # Retry every minute
          };

          services.oauth2-proxy = {
            enable = true;
            httpAddress = "unix://${oauth2ProxiesDir}/${virtualHostName}.sock";
            provider = "oidc";
            scope = "openid email";
            setXauthrequest = true;
            keyFile = "/run/secrets/oauth2-proxy/env-file";
            clientID = snowService.oauth2.clientId;
            loginURL = services.kanidm.urls.oauth2UserAuth;
            redeemURL = services.kanidm.urls.oauth2Token;
            validateURL = services.kanidm.urls.oauth2OidcUserinfo {
              clientId = snowService.oauth2.clientId;
            };

            email.domains = [ "*" ];

            extraConfig = {
              oidc-issuer-url = services.kanidm.urls.oauth2OidcIssuer {
                clientId = snowService.oauth2.clientId;
              };
              code-challenge-method = "S256"; # Enable PKCE
            };
          };
        };
      }
    ) enabledVirtualHosts;
  };
}
