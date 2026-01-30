{
  lib,
  config,
  pkgs,
  ...
}:
{
  services.zigbee2mqtt = {
    enable = true;
    package = pkgs.zigbee2mqtt_2;
    settings = {
      homeassistant.enabled = true;
      availability.enabled = true;
      advanced.last_seen = "ISO_8601";
      frontend = {
        enabled = true;
        port = 4040;
      };
      permit_join = false;
      mqtt = {
        # TODO: figure out why zigbee2mqtt can't seem to resolve mqtt.m. It errors out with a "getaddrinfo EBUSY", as described here: <https://github.com/nodejs/help/issues/2390>
        # server = services.mqtt.baseUrl; # Fails with "getaddrinfo EBUSY"
        # server = "mqtt://[fdd4:aa51:eed9:426:9f99:93d4:aa51:eed9]"; # This works, but cannot work with HTTPS.
        server = "mqtt://mqtt.ec"; # This works, but cannot work with HTTPS.

        base_topic = "zigbee2mqtt";
        user = "zigbee2mqtt";
      };
      # https://www.zigbee2mqtt.io/guide/adapters/zstack.html
      serial = {
        port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4e9906adc812ec118b8a23c7bd930c07-if00-port0";
        adapter = "zstack";
      };
    };
  };

  systemd.services.zigbee2mqtt.serviceConfig = {
    LoadCredential = [
      "password:${config.clan.core.vars.generators.mqtt-zigbee2mqtt.files."password".path}"
    ];
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "zigbee2mqtt-with-creds" ''
        export ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD=$(< $CREDENTIALS_DIRECTORY/password)
        exec ${config.services.zigbee2mqtt.package}/bin/zigbee2mqtt
      ''
    );
  };

  snow.services.zigbee2mqtt.proxyPass = "http://[::1]:${toString config.services.zigbee2mqtt.settings.frontend.port}";

  snow.backup.paths = [ config.services.zigbee2mqtt.dataDir ];
}
