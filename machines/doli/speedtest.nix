{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.librespeed = {
    enable = true;
    domain = services.speedtest-cloud.fqdn;
    frontend = {
      enable = true;
      contactEmail = "me@jfly.fyi";
    };
  };

  snow.services.speedtest-cloud.hostedHere = true;
}
