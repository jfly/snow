{ lib, pkgs, ... }:
{
  services.cryptpad = {
    package = pkgs.cryptpad.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        # Sort files and folders with "natural" sort
        # https://github.com/cryptpad/cryptpad/pull/1739
        (pkgs.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/cryptpad/cryptpad/pull/1739.diff";
          hash = "sha256-65N0SuVPh6FAl/Qq8FDetIT3Ov5Z8C7hn83H/AAvgUY=";
        })
      ];
    });
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
