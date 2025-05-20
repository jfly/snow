{
  lib,
  pkgs,
  ...
}:

{
  services.cryptpad = {
    package = pkgs.cryptpad.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        (pkgs.fetchpatch {
          name = ''Sort files and folders with "natural" sort'';
          url = "https://github.com/cryptpad/cryptpad/commit/36b66c0c2dcc99794352a2d61ae55287d9d8cda9.patch";
          hash = "sha256-DdFe39RCyFKXbUpJHRnmhPjCC+4zmht0ga6OFKOt1ew=";
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

  snow.backup = {
    paths = [
      # This is actually just a symlink to ...
      "/var/lib/cryptpad"
      # This
      "/var/lib/private/cryptpad"
    ];
    # Exclude various unfortunate symlinks to `/nix/store/`.
    # See
    # <https://github.com/NixOS/nixpkgs/blob/9de99ed5360a06e94752385d9ec94a9385b1e253/pkgs/by-name/cr/cryptpad/package.nix#L139-L151>
    # for details.
    exclude = [
      "/var/lib/private/cryptpad/customize.dist"
      "/var/lib/private/cryptpad/lib"
      "/var/lib/private/cryptpad/www"
    ];
  };
}
