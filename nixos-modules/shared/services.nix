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
  publicDomains = [
    "snow.jflei.com"
    "ramfly.net"
  ];
  regenerateCommand = "To fix: nix run .#gen-hosts > nixos-modules/shared/host-to-services.toml";
  hostToServicesFile = ./host-to-services.toml;
  hostToServices = fromTOML (builtins.readFile hostToServicesFile);

  listenAddressesByParentDomain = {
    # For services on our overlay network, *only* listen on our overlay network
    # address. Otherwise anyone with regular, non-overlay IP connectivity to
    # this machine could talk to the virtualHost, thereby defeating the purpose
    # of the overlay network.
    ${config.snow.network.overlay.tld} = [ "[${config.snow.network.overlay.ip}]" ];
  }
  // (lib.optionalAttrs (config.snow.network.lan != null) {
    ${config.snow.network.lan.tld} = [ config.snow.network.lan.ip ];
  })
  // (lib.listToAttrs (
    map (
      publicDomain:
      lib.nameValuePair publicDomain (
        # For public services, listen on all IPs. They're public services!
        [
          "0.0.0.0"
          "[::1]"
        ]
        # This is a bit strange: we have to explicitly listen on the lan IPs as
        # well, even though they're covered by the wildcard addresses above.
        # This is because of how nginx picks `server {}` blocks: it first
        # looks for server blocks with specific IPs, and only after that does
        # it consider server blocks listening on wildcard addresses. When
        # someone inside of the lan tries to talk to a public service, the
        # source IP will be on the LAN: so we need the public service to have
        # an explicit LAN IP as well so its server block doesn't "lose" to a
        # server block for some other lan-only service.
        ++ (lib.optional (config.snow.network.lan != null) config.snow.network.lan.ip)
      )
    ) publicDomains
  ));

  isLanService =
    service: config.snow.network.lan != null && service.parentDomain == config.snow.network.lan.tld;
in
{
  options.snow.generateAllOauth2ClientSecrets = lib.mkEnableOption ''
    Whether to declare a generator for all OAuth2 client secrets.
    Only enable this on the machine hosting the OAuth provider (Kanidm).
  '';

  options.snow.servicesOnThisMachine = {
    all = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      readOnly = true;
      default =
        let
          sortedServices = lib.sortOn (service: service.subdomain) (
            lib.attrValues (lib.filterAttrs (name: service: service.hostedHere) config.snow.services)
          );
          # Put the service that represents this machine first. This has nicer
          # behavior, for example dnsmasq calls it the "canonical name".
          canonicalServices = lib.filter (
            service: service.subdomain == config.networking.hostName
          ) sortedServices;
          remainingServices = lib.filter (
            service: service.subdomain != config.networking.hostName
          ) sortedServices;
        in
        canonicalServices ++ remainingServices;
    };
    public = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      readOnly = true;
      default = lib.filter (
        service: lib.elem service.parentDomain publicDomains
      ) config.snow.servicesOnThisMachine.all;
    };
    private = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      readOnly = true;
      default = lib.filter (
        service: service.parentDomain == config.snow.network.overlay.tld
      ) config.snow.servicesOnThisMachine.all;
    };
    lan = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      readOnly = true;
      default = lib.filter isLanService config.snow.servicesOnThisMachine.all;
    };
  };

  options.snow.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        local@{ name, ... }:
        {
          options = {
            # TODO: rework these 3 options. Perhaps a `hosted = {...}`
            # submodule that's set only on the machine actually hosting the
            # service? That would simplify the logic for `hostedHere`.
            hostedHere = lib.mkOption {
              type = lib.types.bool;
              default = local.config.proxyPass != null || local.config.nginxExtraConfig != null;
            };
            proxyPass = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            nginxExtraConfig = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
            };

            subdomain = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            parentDomain = lib.mkOption {
              type = lib.types.enum (
                [
                  config.snow.network.overlay.tld
                  # LAN TLDs.
                  "ec"
                  "sc"
                ]
                ++ publicDomains
              );
              # Default to private (only accessible on our overlay network).
              default = config.snow.network.overlay.tld;
            };
            fqdn = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${local.config.subdomain}.${local.config.parentDomain}";
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
    services.nginx = lib.mkIf (builtins.length config.snow.servicesOnThisMachine.all > 0) {
      enable = true;
      recommendedProxySettings = true;

      virtualHosts = lib.mkMerge (
        map (
          service:
          let
            httpsOnly = !(isLanService service);
          in
          {
            ${service.fqdn} = {
              enableACME = httpsOnly;
              forceSSL = httpsOnly;

              listenAddresses = listenAddressesByParentDomain.${service.parentDomain};

              locations."/" = {
                proxyPass = service.proxyPass;
                proxyWebsockets = true;
                extraConfig = lib.mkIf (service.nginxExtraConfig != null) service.nginxExtraConfig;
              };
            };
          }
        ) config.snow.servicesOnThisMachine.all
      );
    };

    networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts =
      lib.mkIf (builtins.length config.snow.servicesOnThisMachine.private > 0)
        [
          80
          443
        ];

    # If there are any public services on this machine, then we must open things up further.
    # Note: we also open things up if there are any lan interfaces. It would be
    # better to do this only on the lan interface, but we don't currently track
    # that. This will be more important in the future if we have any routers
    # running NixOS.
    networking.firewall.allowedTCPPorts =
      lib.mkIf
        (
          builtins.length config.snow.servicesOnThisMachine.public > 0
          || builtins.length config.snow.servicesOnThisMachine.lan > 0
        )
        [
          80
          443
        ];

    systemd.services.nginx =
      let
        overlayDeviceService = "sys-subsystem-net-devices-${config.snow.subnets.overlay.interface}.device";
      in
      {
        # Ensure nginx doesn't start up until we're connected to the overlay network.
        after = [ overlayDeviceService ];
        requires = [ overlayDeviceService ];
      };

    # Our step-ca module (used by every machine in the cluster) defaults to
    # querying our self-hosted step-ca for certs. However, that ACME server is
    # only able to generate certs for our "fake" overlay domain. For "real"
    # domain names, we still need to talk to Let's Encrypt.
    # TODO: investigate what would be involved in configuring ACME server globs/regexes.
    security.acme.certs = lib.mkMerge (
      map (service: {
        ${service.fqdn} = {
          server = "https://acme-v02.api.letsencrypt.org/directory";
          renewInterval = "daily";
        };
      }) config.snow.servicesOnThisMachine.public
    );

    networking.extraHosts = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        host: fqdns:
        let
          ip = builtins.readFile ../../vars/per-machine/${host}/zerotier/zerotier-ip/value;
          validFqdns =
            if host != config.networking.hostName then
              fqdns
            else
              let
                # See comment in <packages/gen-hosts/package.nix> for why we're
                # only considering private services.
                expectedFqdns = map (service: service.fqdn) config.snow.servicesOnThisMachine.private;
              in
              assert lib.assertMsg (expectedFqdns == fqdns)
                "Incorrect fqdns for ${host}. Expected: ${builtins.toJSON expectedFqdns}, got: ${builtins.toJSON fqdns}\n\n${regenerateCommand}";
              fqdns;
        in
        "${ip} ${lib.concatStringsSep " " validFqdns}"
      ) hostToServices
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
      fflewddur = { };
      frigate = { };
      grafana = { };
      healthcheck.parentDomain = "snow.jflei.com";
      home-assistant = { };
      home-assistant-lan = {
        # Keep in sync with <routers/strider/files/etc/config/dhcp>.
        subdomain = "home-assistant";
        parentDomain = "ec";
      };
      immich = { };
      immichframe = {
        # Keep in sync with <routers/strider/files/etc/config/dhcp>.
        subdomain = "frame";
        parentDomain = "ec";
      };
      immichframe-sc = {
        # Keep in sync with <http://primary-router.sc/cgi-bin/luci/admin/network/dhcp>.
        subdomain = "frame";
        parentDomain = "sc";
      };
      immich-public-proxy = {
        subdomain = "photos";
        parentDomain = "ramfly.net";
      };
      jackett = { };
      jellyfin = { };
      kanidm = {
        subdomain = "auth";
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
      speedtest.parentDomain = "snow.jflei.com";
      step-ca.subdomain = "ca";
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
