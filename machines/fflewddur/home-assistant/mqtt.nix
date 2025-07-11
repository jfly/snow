{ config, ... }:

{
  # Keep this in sync with `mqtt.ec` in `routers/strider/files/etc/config/dhcp`.
  # and Allow-MQTT* rules in `routers/strider/files/etc/config/firewall`.

  # TODO: port mqtt from kubernetes to here

  # Note that we use nginx to generate a cert for MQTT because nginx is capable
  # of passsing the "host a file" HTTP challenge.
  security.acme.certs."mqtt.mm".reloadServices = [ "haproxy.service" ];
  services.data-mesher.settings.host.names = [ "mqtt" ];
  services.nginx.virtualHosts."mqtt.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      recommendedProxySettings = true;
      extraConfig = ''
        add_header Content-Type text/plain;
        return 200 "There's a MQTT server here at :1883 and a MQTTS server at :8883";
      '';
    };
  };
  systemd.services.haproxy.serviceConfig.LoadCredential = [
    "cert.pem:${config.security.acme.certs."mqtt.mm".directory}/cert.pem"
    "key.pem:${config.security.acme.certs."mqtt.mm".directory}/key.pem"
  ];
  services.haproxy = {
    enable = true;
    config = ''
      defaults
        mode tcp
        timeout client 10s
        timeout connect 5s
        timeout server 10s

      crt-store mqtt
        crt-base "$CREDENTIALS_DIRECTORY"
        key-base "$CREDENTIALS_DIRECTORY"
        load crt "cert.pem" key "key.pem"

      frontend mqtt_fe
        bind [::]:1883
        bind [::]:8883 ssl crt "@mqtt/cert.pem"
        default_backend mqtt_clark

      backend mqtt_clark
        balance leastconn
        server s1 clark.ec:1883
    '';
  };
  networking.firewall.allowedTCPPorts = [
    1883
    8883
  ];
}
