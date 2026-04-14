{ config, ... }:

# Note: the alerts for zrepl failures are over in
# <machines/fflewddur/prometheus/scrapers/zrepl.nix>.

let
  metricsPort = 9811;
  sinkPort = 3912;
  fflewddurIp = builtins.readFile ../../vars/per-machine/fflewddur/zerotier/zerotier-ip/value;
in
{
  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts = [
    metricsPort
    sinkPort
  ];

  services.zrepl = {
    enable = true;
    settings = {
      global = {
        logging = [
          {
            type = "syslog";
            level = "info";
            format = "human";
          }
        ];

        # https://zrepl.github.io/configuration/monitoring.html
        monitoring = [
          {
            type = "prometheus";
            listen = ":${toString metricsPort}";
          }
        ];
      };

      jobs = [
        {
          name = "baykup_sink";
          type = "sink";
          root_fs = "baykup/zrepl/sink";
          serve = {
            type = "tcp";
            listen = ":${toString sinkPort}";
            clients = {
              ${fflewddurIp} = "fflewddur";
            };
          };
        }
      ];
    };
  };
}
