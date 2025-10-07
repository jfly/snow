{ lib, ... }:
{
  # Workaround for
  services.nginx.recommendedBrotliSettings = true;
  services.librespeed = {
    enable = true;
    domain = "speedtest.snow.jflei.com";
    frontend = {
      enable = true;
      contactEmail = "jeremyfleischman@gmail.com";
    };
  };

  # k8s does https termination and proxies to us.
  # TODO: remove when k8s is gone.
  services.nginx.virtualHosts."speedtest.snow.jflei.com" = {
    enableACME = false;
    forceSSL = lib.mkForce false;
  };
}
