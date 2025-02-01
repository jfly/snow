{ pkgs, config, ... }:

{
  imports = [
    ./alertmanager.nix
    # Keep the set of scrapers in sync with the exporters enabled in
    # `nixos-modules/monitoring/default.nix`.
    ./scrapers/up.nix
    ./scrapers/node.nix
  ];

  services.prometheus = {
    enable = true;
    webExternalUrl = "https://prometheus.snow.jflei.com";

    # Set up a dead man's switch to monitor Prometheus itself.
    # Modeled after this blog post:
    # <https://jakubstransky.com/2019/01/26/who-monitors-prometheus/>.
    ruleFiles = [
      (pkgs.writeText "dead-man-switch.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "dead-man-switch";
              rules = [
                {
                  alert = "DeadManSwitch";
                  expr = "vector(1)";
                  labels.service = "deadman";
                  annotations.summary = "Alert that should always be firing (as a dead man's switch).";
                }
              ];
            }
          ];
        }
      ))
    ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."prometheus.snow.jflei.com" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
      };
    };
  };
}
