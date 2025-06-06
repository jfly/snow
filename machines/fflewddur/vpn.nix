{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.clan-core.clanModules.zerotier-static-peers ];

  # How to add a mobile device to the network:
  # 1. Install ZeroTier One app.
  # 2. Connect to network "d4aa51eed904269f".
  #    - Enable "Network DNS".
  #      - Note: iOS has a bug where this doesn't work. Instead, select "Custom
  #              DNS" and add fflewddur's IPv6 address. See
  #              https://github.com/zerotier/ZeroTierOne/issues/2464
  #
  #    - For Android, enable "Route all traffic through ZeroTier. Requires external
  #      configuration of the network".
  #
  #      Why? This allows the `2000::` hack (see
  #      below) to work, which enables AAAA DNS lookups over ZeroTier even when
  #      you're on an IPv4-only network.
  #
  #      Note: this does not actually route all traffic through Zerotier. It
  #      just ingests the routes the controller advertises.
  #      TODO: file an issue with https://github.com/zerotier/ZeroTierOne/ and
  #            confirm I'm understanding this correctly.
  # 3. Add the node id here. To confirm, you can run `sudo zerotier-members list`
  #    on the controller (you may have to wait a while before this works).
  clan.zerotier-static-peers.networkIds = [
    "d1064a4d50" # jfly phone
    "fce56a3a26" # ansible
    "06fda2b62d" # ram mbp
  ];

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

  # TODO: contribute docs to clan-core explaining how to do all this:
  #       https://git.clan.lol/clan/clan-core/issues/1268

  # TODO: back up controller data
}
