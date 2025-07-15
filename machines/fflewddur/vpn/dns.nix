{ flake, config, ... }:
{
  imports = [ flake.nixosModules.gaidns ];

  # We run a DNS server for the members of our VPN that do not support
  # data-mesher.
  # See <https://git.clan.lol/clan/data-mesher/issues/223>.
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];
  services.gaidns.enable = true;
  # Disable the systemd-resolve stub DNS server to make way for gaidns.
  # Alternatively, we could have gaidns bind on
  # `config.services.data-mesher.settings.cluster.interface`, but it doesn't
  # have the ability to do that.
  services.resolved.extraConfig = ''
    DNSStubListener=no
  '';

  clan.core.networking.zerotier.settings = {
    # Make this DNS server available for easy client configuration. Clients can
    # choose to use the DNS settings provided by a ZeroTier controller when
    # they connect.
    dns = {
      "domain" = config.snow.tld;
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
