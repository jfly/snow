{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (config.snow) services;
  deercamPasswordKeyId = "deercam-password-id";
in
{
  services.frigate.enable = true;
  services.frigate.hostname = services.frigate.fqdn;
  services.data-mesher.settings.host.names = [ services.frigate.sld ];
  # `checkConfig` doesn't work in the sandbox where we do not have a
  # `FRIGATE_DEERCAM_PASSWORD` env var. It would be nice to provide a hook for people
  # to "stub out" some of the problematic stuff in the sandbox (for instance, I
  # could set a dummy value for some secret environment variables).
  services.frigate.checkConfig = false;
  services.frigate.settings.cameras = {
    ratcam = {
      enabled = true;
      ffmpeg = {
        # https://docs.frigate.video/configuration/hardware_acceleration_video/#setup-decoder
        hwaccel_args = "preset-nvidia";
        inputs = [
          # I configured 2 streams as documented on
          # <https://docs.frigate.video/frigate/camera_setup#example-camera-configuration>.
          # The RTSP urls for this camera are documented on
          # <https://support.amcrest.com/hc/en-us/articles/360052688931-Accessing-Amcrest-Products-Using-RTSP>.
          {
            path = "rtsp://admin:{FRIGATE_DEERCAM_PASSWORD}@deercam.ec:554/cam/realmonitor?channel=1&subtype=0";
            roles = [ "record" ];
          }
          {
            path = "rtsp://admin:{FRIGATE_DEERCAM_PASSWORD}@deercam.ec:554/cam/realmonitor?channel=1&subtype=2";
            roles = [ "detect" ];
          }
        ];
      };
      detect.enabled = false; # As the docs warn: this is just too CPU intensive.
      record = {
        enabled = true;
        # Retain settings copied from
        # <https://docs.frigate.video/configuration/record/#most-conservative-ensure-all-video-is-saved>
        retain = {
          days = 3;
          mode = "all";
        };
        alerts.retain = {
          days = 30;
          mode = "motion";
        };
        detections.retain = {
          days = 30;
          mode = "motion";
        };
      };
    };
  };

  services.nginx.virtualHosts.${services.frigate.fqdn} = {
    enableACME = true;
    forceSSL = true;
  };

  clan.core.vars.generators.deercam = {
    prompts.password = {
      description = "Password for deercam";
      persist = true;
    };
  };

  systemd.services.frigate.serviceConfig = {
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "frigate-with-secrets" ''
        export FRIGATE_DEERCAM_PASSWORD=$(< "$CREDENTIALS_DIRECTORY/${deercamPasswordKeyId}")
        # Entrypoint copied from upstream
        # <https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/video/frigate.nix#L642>.
        exec ${config.services.frigate.package.python.interpreter} -m frigate
      ''
    );
    LoadCredential = [
      "${deercamPasswordKeyId}:${config.clan.core.vars.generators.deercam.files."password".path}"
    ];
  };
}
