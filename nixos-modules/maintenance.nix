# Defines a pretty minimal target for maintenance. To start this (and stop all
# unnecessary services):
#
#   systemctl isolate maintenance.target
let
  units = [
    "local-fs.target"
    "network-online.target"
    "systemd-networkd.service"
    "sshd.service"
    "zerotierone.service"
  ];
in
{
  systemd.targets.maintenance = {
    description = "Maintenance Mode";
    requires = units;
    after = units;
    unitConfig.AllowIsolate = "yes";
  };
}
