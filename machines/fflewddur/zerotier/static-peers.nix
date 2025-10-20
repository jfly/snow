# It was once possible to manage non-Clan ZeroTier peers declaratively. This
# empty file sits here as a place to document how to do it imperatively. Pay
# attention to
# <https://git.clan.lol/clan/clan-core/issues/1268#issuecomment-30759> to hope
# for this to get easier in the future.
#
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
# 3. Authorize the node id with `sudo zerotier-members allow ...`. To confirm,
#    you can run `sudo zerotier-members list` on the controller (you may have to
#    wait a while before this works).
#
# Devices:
#   - "06557d77cb" # jfly phone
#   - "b504d84a2e" # jfly phone (newer)
#   - "397eeab368" # jfly tablet
#   - "fce56a3a26" # ansible
#   - "06fda2b62d" # ram mbp
#   - "8d0ee1ad66" # ram desktop
#   - "d83fdfb31b" # waydroid
#   - "c86a6ffd1f" # ospi
#   - "eee8a3e616" # gurgi
{ }
