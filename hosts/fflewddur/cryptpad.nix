{ lib, ... }:
{
  services.cryptpad = {
    enable = true;
    configureNginx = true;
    settings = {
      httpUnsafeOrigin = "https://cryptpad.snow.jflei.com";
      httpSafeOrigin = "https://cryptpad-ui.snow.jflei.com";
      adminKeys = [
        "[jfly@cryptpad.snow.jflei.com/ZwwZaxCmQTnfQI7WZ1BRrrhbKKYLvLmanv03UGJPtks=]"
        "[rachel@cryptpad.snow.jflei.com/Su7meyEBZ4vs-kTXFwHHoZghJeun9mRgOUgVGsVhLVg=]"
      ];
    };
  };

  # Disable ACME/SSL. This isn't exposed to the outside, it's all proxied via
  # our `k3s` cluster which does HTTPS termination.
  services.nginx.virtualHosts."cryptpad.snow.jflei.com" = {
    enableACME = false;
    forceSSL = lib.mkForce false;
  };

  # TODO: backup `/var/lib/cryptpad`
  # TODO: look through options here:
  # https://docs.cryptpad.org/en/admin_guide/customization.html#restricting-guest-access,
  # probably want to close registration? Might want to continue to allow guest
  # access.
}
