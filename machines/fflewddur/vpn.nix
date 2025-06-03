{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.clan-core.clanModules.zerotier-static-peers ];

  # How to add a non-NixOS device to the network:
  # 1. Install ZeroTier One.
  # 2. Connect to network "d4aa51eed904269f". Be sure to enable "Network DNS".
  # 3. Add the node id here. To confirm, you can run `sudo zerotier-members
  #    list` on fflewddur (you may have to wait a while before this works).
  clan.zerotier-static-peers.networkIds = [
    "d1064a4d50" # jfly phone
  ];

  # We run a DNS server for the members of our VPN that do not support
  # data-mesher.
  # See <https://git.clan.lol/clan/data-mesher/issues/223>.
  # This requires some manual configuration on the VPN controller:
  #  1. Need to add the DNS server. Try something like this:
  #     ```
  #     $ curl -s \
  #         -H "X-ZT1-Auth: $(sudo cat /var/lib/zerotier-one/authtoken.secret)" \
  #         -d '{"dns": {"domain": "<ZEROTIER DOMAIN>", "servers": ["<ZEROTIER IP OF DNS SERVER>"]}}' \
  #         -X POST http://localhost:9993/controller/network/<ZEROTIER NETWORK ID>
  #     ```
  #     (get the Zerotier network id from `sudo zerotier-cli listnetworks`)
  #  2. Need to add a bogus IPv6 route for `2000::` to trick Android into doing
  #     AAAA DNS lookups even when only connected to the internet via IPv4. See
  #     this excellent SO answer [0] and relevant Android source code [1]
  #     I ran something like this:
  #     ```
  #     $ curl -s \
  #         -H "X-ZT1-Auth: keny22ndwa6nbwkhq9owtn81" \
  #         -d '{"routes": [{"target": "2000::"}]}' \
  #         -X POST http://localhost:9993/controller/network/<ZEROTIER NETWORK ID>
  #     ```
  #
  #     TODO: contribute a Zerotier controller module to clan-core so I can
  #           managed this stuff declaratively. See API docs here:
  #           https://docs.zerotier.com/api/service/ref-v1/#tag/Controller
  #
  #     TODO: contribute docs to clan-core explaining how to do all this:
  #           https://git.clan.lol/clan/clan-core/issues/1268
  #
  #     [0]: https://android.stackexchange.com/a/257790
  #     [1]: https://cs.android.com/android/platform/superproject/main/+/main:packages/modules/DnsResolver/getaddrinfo.cpp;l=228;drc=442fcb158a5b2e23340b74ce2e29e5e1f5bf9d66

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
}
