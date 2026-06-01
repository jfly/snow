{ config, ... }:
let
  inherit (config.snow) services;
  babycamPasswordKeyId = "babycam-password-id";
in
{
  services.go2rtc = {
    enable = true;
    settings = {
      # I configured 2 streams as documented on
      # <https://docs.frigate.video/frigate/camera_setup#example-camera-configuration>.
      # The RTSP urls for this camera are documented on
      # <https://support.amcrest.com/hc/en-us/articles/360052688931-Accessing-Amcrest-Products-Using-RTSP>.
      streams.babycam-record = "rtsp://admin:\${${babycamPasswordKeyId}}@babycam.ec:554/cam/realmonitor?channel=1&subtype=0";
      streams.babycam-detect = "rtsp://admin:\${${babycamPasswordKeyId}}@babycam.ec:554/cam/realmonitor?channel=1&subtype=2";
      rtsp.listen = ":8554";
    };
  };

  systemd.services.go2rtc.serviceConfig.LoadCredential = [
    "${babycamPasswordKeyId}:${config.clan.core.vars.generators.babycam.files."password".path}"
  ];

  # If this is too slow, consider putting this data on the SSD rootfs and backing it up some other way.
  # I'm intentionally avoiding our snow.backup infrastructure, as that keeps all
  # historical data, which would quickly grow unreasonable with frigate's data.
  fileSystems."/var/lib/frigate" = {
    device = "/mnt/bay/media/videos/frigate";
    fsType = "none";
    options = [ "bind" ];
  };

  systemd.services.frigate.unitConfig = {
    RequiresMountsFor = "/mnt/bay/media/videos/frigate";
  };

  services.frigate.enable = true;
  services.frigate.hostname = services.frigate.fqdn;
  snow.services.frigate.hostedHere = true;

  services.frigate.settings.cameras = {
    babycam = {
      enabled = true;
      ffmpeg = {
        # https://docs.frigate.video/configuration/hardware_acceleration_video/#setup-decoder
        hwaccel_args = "preset-nvidia";
        inputs = [
          {
            path = "rtsp://127.0.0.1:8554/babycam-record";
            input_args = "preset-rtsp-restream";
            roles = [ "record" ];
          }
          {
            path = "rtsp://127.0.0.1:8554/babycam-detect";
            input_args = "preset-rtsp-restream";
            roles = [ "detect" ];
          }
        ];
      };
      detect.enabled = false; # As the docs warn: this is just too CPU intensive.
      record = {
        enabled = true;
        # Retain settings copied from
        # <https://docs.frigate.video/configuration/record/#most-conservative-ensure-all-video-is-saved>
        continuous.days = 3;
        motion.days = 7;
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

  clan.core.vars.generators.babycam = {
    prompts.password = {
      description = "Password for babycam";
      persist = true;
    };
  };
}
