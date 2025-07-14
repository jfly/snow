{ lib, pkgs, ... }:

let
  user = "root";
  group = "media";
in
{
  services.data-mesher.settings.host.names = [ "budget" ];
  services.nginx.virtualHosts."budget.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:3000";
      proxyWebsockets = true;
    };
  };

  systemd.services.manmanmon = {
    description = "manmanmon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "notify";
      NotifyAccess = "all"; # The service invokes `systemd-notify --ready` as a subprocess.
      ExecStart = "${lib.getExe pkgs.nix} develop --command just run-prod https://budget.mm";
      WorkingDirectory = "/state/git/manmanmon";
      User = user;
      Group = group;
      TimeoutStartSec = "300s"; # We do *entirely* too much work at startup. It takes a while.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Regularly fetch the latest data.
  systemd.services.manmanmon-fetch = {
    description = "manmanmon fetch";
    # Reset the git working directory if necessary (this lets us recover from
    # previous failed imports).
    environment.MANMAN_RESET_REPO_IF_NECESSARY = "1";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.nix} develop --command just fetch-and-commit";
      ExecStartPost = pkgs.writeShellScript "post-fetch" ''
        echo "Fetch succeeded, restarting server."
        ${pkgs.systemd}/bin/systemctl restart manmanmon.service
      '';
      WorkingDirectory = "/state/git/manmanmon";
      User = user;
      Group = group;
    };
  };
  systemd.timers.manmanmon-fetch = {
    description = "Run manmanmon fetch";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
