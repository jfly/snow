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
      contactEmail = "jeremyfleischman@gmail.com";
    };
  };

  snow.services.speedtest.hostedHere = true;
}
