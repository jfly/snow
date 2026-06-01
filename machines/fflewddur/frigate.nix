{ config, ... }:
let
  inherit (config.snow) services;
  babycamPasswordKeyId = "babycam-password-id";
  secondsPer = {
    minute = 60;
    hour = 60 * secondsPer.minute;
    day = 24 * secondsPer.hour;
    month = 30 * secondsPer.day;
  };
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

  # We don't back up frigate, as that keeps all historical data, which would
  # quickly grow unreasonable with frigate's ever changing data.
  # The expectation is that we quickly export anything "interesting" to somewhere persistent.
  snow.backup.exclude = [ "/var/lib/frigate" ];

  services.frigate.enable = true;
  services.frigate.hostname = services.frigate.fqdn;
  snow.services.frigate.hostedHere = true;

  services.frigate.settings.auth = {
    cookie_secure = true;
    session_length = 3 * secondsPer.month;
  };

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
