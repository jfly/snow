{
  lib,
  config,
  pkgs,
  ...
}:
let
  mqttUsername = "zigbee2mqtt";
in
{
  services.zigbee2mqtt = {
    enable = true;
    package = pkgs.zigbee2mqtt_2;
    settings = {
      homeassistant.enabled = true;
      availability.enabled = true;
      advanced.last_seen = "epoch";

      # Retain messages so tools like mqtt-exporter* will not see data until a
      # device happens to send new information. For alerts like LongTimeNoSee,
      # where we're alerting about a device that has likely disappears, that
      # device is never going to send more data. In other words: without retain,
      # if mqtt-exporter restarts, prometheus will completely forget about Zigbee
      # devices that have stopped reporting, and we won't get paged about them.
      # There's discussion about making this the default behavior upstream
      # <https://github.com/Koenkk/zigbee2mqtt/issues/27216>, but it's not getting
      # a lot of traction because most people probably just wire this up to
      # Home Assistant, which implements birth/last will messages that instruct
      # zigbee2mqtt to re-send data.
      #
      # *Which is how metrics like zigbee device "last seen" get to prometheus for alerting
      device_options.retain = true;

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
        user = mqttUsername;
      };
      # https://www.zigbee2mqtt.io/guide/adapters/zstack.html
      serial = {
        port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_4e9906adc812ec118b8a23c7bd930c07-if00-port0";
        adapter = "zstack";
      };
    };
  };

  # The default is to not deploy the password, but we need it to configure the service.
  # Note: this only works because we happen to be deploying this to the same
  # machine that provisions mqtt users. A more correct version of this would
  # probably involve something like Clan's inventory system.
  clan.core.vars.generators."mqtt-${mqttUsername}".files.password.deploy = true;

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
}
