{ config, pkgs, ... }:
{
  # We run a DNS server for the members of our VPN that do not support
  # data-mesher.
  # See <https://git.clan.lol/clan/data-mesher/issues/223>.
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
  services.coredns = {
    enable = true;
    package = pkgs.coredns.override {
      externalPlugins = [
        {
          position = "start-of-file"; # This should happen *before* we forward requests to another DNS server.
          name = "data-mesher";
          repo = "github.com/jfly/coredns-data-mesher";
          version = "v0.1.3";
        }
      ];
      vendorHash = "sha256-fXzY3IqTVHhpixoMdD71AxpBthZDBkVcXUFOATXWLUA=";
    };

    # Ideally we'd only respond to queries for the "mm" zone, but Android (or
    # Android's Zerotier app) don't support split DNS, so we unfortunately end
    # up receiving *all* queries.
    # https://github.com/zerotier/ZeroTierOne/issues/2400
    config = ''
      . {
        bind ${config.services.data-mesher.settings.cluster.interface}

        data-mesher
        # Keep this in sync with routers/strider/files/etc/config/network
        forward . 1.1.1.1 1.0.0.1
      }
    '';
  };

  clan.core.networking.zerotier.settings = {
    # Make this DNS server available for easy client configuration. Clients can
    # choose to use the DNS settings provided by a ZeroTier controller when
    # they connect.
    dns = {
      "domain" = config.networking.domain;
      "servers" = [ config.clan.core.vars.generators.zerotier.files.zerotier-ip.value ];
    };

    # We add a bogus IPv6 route for `2000::` to trick Android into doing
    # AAAA DNS lookups even when only connected to the internet via IPv4. See
    # this excellent SO answer [0] and relevant Android source code [1].
    #
    # [0]: https://android.stackexchange.com/a/257790
    # [1]: https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/DnsResolver/getaddrinfo.cpp;l=228;drc=442fcb158a5b2e23340b74ce2e29e5e1f5bf9d66
    routes = [
      { target = "2000::"; }
    ];
  };
}
