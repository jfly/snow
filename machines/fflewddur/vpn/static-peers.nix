{ inputs, ... }:
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
  #      TODO: figure out why this requires checking this box, it doesn't
  #            seem to do what I'd expect from the name.
  #    - For macOS, disable DNS service coupling: `sudo scutil --disable-service-coupling on`
  #      TODO: write up a proper explanation for this. See notes in
  #            <https://github.com/apple-oss-distributions/configd/compare/main...jfly:configd:notes?expand=1>.
  # 3. Add the node id here. To confirm, you can run `sudo zerotier-members list`
  #    on the controller (you may have to wait a while before this works).
  clan.zerotier-static-peers.networkIds = [
    "06557d77cb" # jfly phone
    "fce56a3a26" # ansible
    "06fda2b62d" # ram mbp
    "8d0ee1ad66" # ram desktop
  ];
}
