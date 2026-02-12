{
  config,
  lib,
  pkgs,
  flake',
  ...
}:

let
  inherit (config.snow) services;

  certs = config.security.acme.certs."${services.kanidm.fqdn}";
  oauth2Services = lib.filterAttrs (name: service: service.oauth2 != null) config.snow.services;
in
{
  # We need access to all OAuth2 client secrets so we can add them to Kanidm.
  snow.generateAllOauth2ClientSecrets = true;

  clan.core.vars.generators = lib.mkMerge (
    [
      {
        kanidm = {
          files.admin-password = {
            owner = config.systemd.services.kanidm.serviceConfig.User;
            group = config.systemd.services.kanidm.serviceConfig.Group;
          };
          files.idm-admin-password = {
            owner = config.systemd.services.kanidm.serviceConfig.User;
            group = config.systemd.services.kanidm.serviceConfig.Group;
          };
          runtimeInputs = [ pkgs.xkcdpass ];
          script = ''
            xkcdpass --numwords 4 --delimiter - --count 1 | tr -d "\n" > "$out"/admin-password
            xkcdpass --numwords 4 --delimiter - --count 1 | tr -d "\n" > "$out"/idm-admin-password
          '';
        };
      }
    ]
    ++ (lib.mapAttrsToList (serviceName: service: {
      # Ensure the oauth secrets are readable by the Kanidm service.
      # Ideally we'd handle this with systemd's LoadCredential functionality
      # instead...
      "kanidm-oauth2-${serviceName}" = {
        files.basic-secret = {
          mode = "0440";
          group = "kanidm";
        };
      };
    }) oauth2Services)
  );

  services.kanidm = {
    package = flake'.packages.kanidm.withSecretProvisioning;
    server = {
      enable = true;
      settings = {
        domain = services.kanidm.fqdn;
        bindaddress = "127.0.0.1:9443";
        origin = services.kanidm.baseUrl;
        tls_chain = "${certs.directory}/fullchain.pem";
        tls_key = "${certs.directory}/key.pem";
      };
    };
    provision = {
      enable = true;

      adminPasswordFile = config.clan.core.vars.generators.kanidm.files.admin-password.path;
      idmAdminPasswordFile = config.clan.core.vars.generators.kanidm.files.idm-admin-password.path;

      # Membership to this group is managed imperatively. See ./README.md for details.
      groups."manman".overwriteMembers = false;

      # Budget
      groups.${services.budget.oauth2.groups.access}.members = [ "manman" ];
      systems.oauth2.${services.budget.oauth2.clientId} = {
        displayName = "Budget";
        # https://www.svgrepo.com/download/314973/piggy-bank.svg
        imageFile = ../../../fods/piggy-bank-svgrepo-com.svg;
        originUrl = services.budget.urls.oauth2Callback;
        originLanding = services.budget.baseUrl;
        basicSecretFile = services.budget.oauth2.clientSecretPath;
        preferShortUsername = true;
        scopeMaps.${services.budget.oauth2.groups.access} = [
          "openid"
          "email"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.${services.budget.oauth2.groups.access} = [ services.budget.oauth2.groups.access ];
        };
      };

      # Whoami
      groups.${services.whoami.oauth2.groups.access}.members = [ "manman" ];
      systems.oauth2.${services.whoami.oauth2.clientId} = {
        displayName = "Whoami";
        # https://www.svgrepo.com/download/483473/detective-face.svg
        imageFile = ../../../fods/detective-face-svgrepo-com.svg;
        originUrl = services.whoami.urls.oauth2Callback;
        originLanding = services.whoami.baseUrl;
        basicSecretFile = services.whoami.oauth2.clientSecretPath;
        preferShortUsername = true;
        scopeMaps.${services.whoami.oauth2.groups.access} = [
          "openid"
          "email"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.${services.whoami.oauth2.groups.access} = [ services.whoami.oauth2.groups.access ];
        };
      };

      # Miniflux
      groups.${services.miniflux.oauth2.groups.access}.members = [ "manman" ];
      systems.oauth2.${services.miniflux.oauth2.clientId} = {
        displayName = "Miniflux";
        # https://www.svgrepo.com/download/204349/rss.svg
        imageFile = ../../../fods/rss-svgrepo-com.svg;
        originUrl = services.miniflux.urls.oauth2Callback;
        originLanding = services.miniflux.baseUrl;
        basicSecretFile = services.miniflux.oauth2.clientSecretPath;
        preferShortUsername = true;
        scopeMaps.${services.miniflux.oauth2.groups.access} = [
          "openid"
          "email"
          "profile"
        ];
        claimMaps.groups = {
          joinType = "array";
          valuesByGroup.${services.miniflux.oauth2.groups.access} = [
            services.miniflux.oauth2.groups.access
          ];
        };
      };
    };
  };

  systemd.services.kanidm = {
    after = [ "acme-selfsigned-internal.${services.kanidm.fqdn}.target" ];
    serviceConfig = {
      SupplementaryGroups = [ certs.group ];
    };
  };

  snow.services.kanidm.proxyPass = "https://${config.services.kanidm.server.settings.bindaddress}";
}
