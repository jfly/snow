{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.librespeed = {
    enable = true;
    domain = services.speedtest.fqdn;
    frontend = {
      enable = true;
      contactEmail = "me@jfly.fyi";
    };
  };

  snow.services.speedtest.hostedHere = true;
}
