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
    enableServer = true;
    package = flake'.packages.kanidm.withSecretProvisioning;
    serverSettings = {
      domain = services.kanidm.fqdn;
      bindaddress = "127.0.0.1:9443";
      origin = services.kanidm.base_url;
      tls_chain = "${certs.directory}/fullchain.pem";
      tls_key = "${certs.directory}/key.pem";
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
        imageFile = pkgs.fetchurl {
          url = "https://www.svgrepo.com/download/314973/piggy-bank.svg";
          hash = "sha256-6avNiA0zQpLBFMHkHHWs1E17iXpLNskDFpvGENuukOY=";
        };
        originUrl = services.budget.urls.oauth2Callback;
        originLanding = services.budget.base_url;
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
        imageFile = pkgs.fetchurl {
          url = "https://www.svgrepo.com/download/483473/detective-face.svg";
          hash = "sha256-44f5uE37wZ6180ppOT4NiigPzgPzaz1sTMuTmVQTdHM=";
        };
        originUrl = services.whoami.urls.oauth2Callback;
        originLanding = services.whoami.base_url;
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
        imageFile = pkgs.fetchurl {
          url = "https://www.svgrepo.com/download/204349/rss.svg";
          hash = "sha256-4bIBbSK6C6f6svL8CyfeRLD0j+gkrDdq4OSZnQmFE7k=";
        };
        originUrl = services.miniflux.urls.oauth2Callback;
        originLanding = services.miniflux.base_url;
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

  services.data-mesher.settings.host.names = [ "auth" ];
  services.nginx.virtualHosts.${services.kanidm.fqdn} = {
    forceSSL = true;
    enableACME = true;
    locations."/".proxyPass = "https://${config.services.kanidm.serverSettings.bindaddress}";
  };
}
