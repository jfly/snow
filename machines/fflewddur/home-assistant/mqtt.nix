{
  lib,
  config,
  pkgs,
  ...
}:

let
  user = config.services.haproxy.user;
  group = config.services.haproxy.group;
  stateDir = "/run/haproxy";
in
{
  # Keep this in sync with `mqtt.ec` in `routers/strider/files/etc/config/dhcp`
  # and Allow-MQTT* rules in `routers/strider/files/etc/config/firewall`.

  # TODO: port MQTT from kubernetes to here

  # Note that we use nginx to generate a cert for MQTT because nginx is capable
  # of passing the "host a file" HTTP challenge.
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
  systemd.services.haproxy.serviceConfig = {
    LoadCredential = [
      "cert.pem:${config.security.acme.certs."mqtt.mm".directory}/cert.pem"
      "key.pem:${config.security.acme.certs."mqtt.mm".directory}/key.pem"
    ];

    ExecStartPre = lib.mkBefore (
      pkgs.writeShellScript "haproxy-exec-pre" ''
        mkdir -p "${stateDir}/credentials"
        chown ${user}:${group} "${stateDir}/credentials"

        cp -f "$CREDENTIALS_DIRECTORY"/cert.pem "${stateDir}/credentials/cert.pem"
        chown ${user}:${group} "${stateDir}/credentials/cert.pem"

        cp -f "$CREDENTIALS_DIRECTORY"/key.pem "${stateDir}/credentials/key.pem"
        chown ${user}:${group} "${stateDir}/credentials/key.pem"
      ''
    );
  };
  services.haproxy = {
    enable = true;
    config = ''
      defaults
        mode tcp
        timeout connect 5s
        timeout client 5m
        timeout server 5m

      crt-store mqtt
        crt-base ${stateDir}/credentials
        key-base ${stateDir}/credentials
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
