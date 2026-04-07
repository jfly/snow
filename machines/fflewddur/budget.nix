{
  flake,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.snow) services;

  unprotectedBaseUrl = "http://localhost:3200";

  forgeKnownHosts = pkgs.writeTextFile {
    name = "forge-known-hosts";
    # Generated with `ssh-keyscan forge.m`
    text = ''
      # forge.m:22 SSH-2.0-OpenSSH_10.2
      forge.m ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/Q5lJplYJUVNSwKorJrI3c7ieJHyV4NJEPi6cOJYlMQEu472QPwKRZDp5wcWk4aDKnQy6DiltDXdY8kxb8NWa1eI6bec29G98FOMaL1yzQO3vUni54RM2Dp4gKlykdKmijmQE0DbyPlfHyTlIdU13xFgsSTme6lPq8D6EK7CiQdWVS+qoqsg//zvFgAzNcBk4MDhfaB5+2F84OQXX+bwvxvD9axPdt0RPwO1EImIBYSbxDVCaT3yFhheiTkL+KdNYjvq4tVqXVq1GCVVN4LXonrTzr4ZVOZeJ3IaoFoCgAGXxc5S/k07BQRzk/csfODbMDhNvnWRMXFhR9zn7Davc1+KVlGvSibSIShxYPrHO86g6ZBJmqGTI6Ndh/VGlJes05O4WSwWi29QbzL97Hdovyxwnqiu2L9NXLHvRbe11ctnm2RNELSUhnQyPSSV20sDwQDb3pNMmjbC5qsg+j5C98Cj6bMz8B4mYzYDmuz6hIoga47zu0QMNYVTO88MxnE9GWIGabn125psHVYsNN80w4X5qZvZGiSImCvrIK/NpQReJP1Hw9xFEYNlHmZr4l1uPWHf0wr2jvRnmz0R9aZeYUdyBoCSD4jAd0+iihSWDz0h7cbstpdgQ60n7KKygBqnk1D1obz1ntMnvy+DMkIkmbcV3oFzRGnXIPRtmh53HyQ==
      # forge.m:22 SSH-2.0-OpenSSH_10.2
      # forge.m:22 SSH-2.0-OpenSSH_10.2
      forge.m ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGCWY5feWfEVA+x6xRX9Qyve9aAkfRxBqOBgqln/RofP
      # forge.m:22 SSH-2.0-OpenSSH_10.2
      # forge.m:22 SSH-2.0-OpenSSH_10.2
    '';
  };
in
{
  imports = [
    flake.nixosModules.oauth2-proxies-nginx
  ];

  snow.services.budget.proxyPass = unprotectedBaseUrl;

  services.nginx.virtualHosts.${services.budget.fqdn} = {
    snow.oauth2 = {
      enable = true;
      snowService = services.budget;
      allowedGroups = [ services.budget.oauth2.groups.access ];
    };
  };

  # Once generated, add as a deploy key on <https://forge.m/jfly/manmanmon/settings/keys>.
  clan.core.vars.generators.budget-deploy-key = {
    files."key" = { };
    files."key.pub".secret = false;
    runtimeInputs = [ pkgs.openssh ];
    script = ''
      ssh-keygen -t ed25519 -f $out/key -P "" -C budget-deploy-key
    '';
  };

  systemd.services.manmanmon = {
    description = "manmanmon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      GIT_SSH_COMMAND = "ssh -i %d/budget-deploy-key -o IdentitiesOnly=yes -o UserKnownHostsFile=${forgeKnownHosts}";

      # Reset the git working directory if necessary (this lets us recover from
      # previous failed imports).
      MANMAN_RESET_REPO_IF_NECESSARY = "1";
    };

    serviceConfig = {
      Type = "notify";
      # We do a lot of things here that are not compatible with DynamicUser.
      # For example, we try to run executables from the CacheDirectory (where
      # we clone the repo), but we DynamicUser, that directory is mounted with
      # `noexec`.
      DynamicUser = false;
      CacheDirectory = "manmanmon";
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "budget-start";
          runtimeInputs = [
            pkgs.git
            pkgs.openssh # used by git clone
          ];
          text = ''
            # Various nix cli commands expect there to be a `XDG_CACHE_HOME`
            # they can store stuff in.
            export XDG_CACHE_HOME=$CACHE_DIRECTORY/.cache

            cd "$CACHE_DIRECTORY"
            if [ ! -e ./manmanmon ]; then
              ${lib.getExe pkgs.git} clone ssh://forgejo@forge.m/jfly/manmanmon.git ./manmanmon
            fi

            cd ./manmanmon

            if [ -n "$(git status --porcelain)" ]; then
              echo "Cleaning repo..."
              git reset --hard
              git clean -dxf
            fi

            echo "Reseting to $(git rev-parse --abbrev-ref '@{upstream}')"
            git fetch origin
            git reset --hard '@{upstream}'

            echo "Starting server..."
            exec ${lib.getExe pkgs.nix} develop --command just run-prod ${services.budget.baseUrl}
          '';
        }
      );

      LoadCredential = [
        "budget-deploy-key:${config.clan.core.vars.generators.budget-deploy-key.files."key".path}"
      ];
      NotifyAccess = "all"; # The service invokes `systemd-notify --ready` as a subprocess.
      TimeoutStartSec = "300s"; # We do *entirely* too much work at startup. It takes a while.
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Regularly fetch the latest data.
  systemd.services.manmanmon-fetch = {
    description = "manmanmon fetch";
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      ExecStart = "${lib.getExe pkgs.curl} --no-progress-meter -X POST ${unprotectedBaseUrl}/api/fetch?commit=1";
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
