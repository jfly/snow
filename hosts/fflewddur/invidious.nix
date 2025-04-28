{ config, ... }:

let
  invCompanionKey = "TODO"; # <<<
in
{
  services.invidious = {
    enable = true;
    settings.db.user = "invidious";
    port = 3333;

    domain = "yt2.snow.jflei.com"; # <<<
    nginx.enable = true;
    # <<< sig-helper.enable = true;

    settings = {
      invidious_companion_key = invCompanionKey;
      invidious_companion = {
        private_url = "http://localhost:8282"; # <<<
        public_url = "https://yt2.snow.jflei.com"; # <<<
      };
    };
  };

  # Set up Invidious companion, as Invidious sig helper doesn't seem to be
  # working for me.
  # https://docs.invidious.io/companion-installation/
  # TODO: upstream a NixOS module to nixpkgs?
  virtualisation.oci-containers.containers = {
    hackagecompare = {
      image = "quay.io/invidious/invidious-companion:latest";
      ports = [ "127.0.0.1:8282:8282" ];
      volumes = [
        "companioncache:/var/tmp/youtubei.js:rw"
      ];
      environment = {
        SERVER_SECRET_KEY = invCompanionKey;
      };
    };
  };

  services.nginx.virtualHosts."${config.services.invidious.domain}" = {
    # Disable ACME/SSL. This isn't exposed to the outside, it's all proxied via
    # our `k3s` cluster which does HTTPS termination.
    enableACME = false;
    forceSSL = false;
  };
}
