{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.snow) services;

  mqttPasswordKeyId = "mqtt-pass";
  mqttUsername = config.services.prometheus.exporters.mqtt.mqttUsername;
in
{
  services.prometheus = {
    exporters.mqtt = {
      enable = true;
      port = 9001;
      package = pkgs.mqtt-exporter.overrideAttrs (oldAttrs: {
        postPatch = ""; # Workaround for <https://github.com/NixOS/nixpkgs/pull/485253>
        patches = oldAttrs.patches or [ ] ++ [
          (pkgs.fetchpatch {
            name = "Catchup with master";
            url = "https://github.com/kpetremann/mqtt-exporter/compare/kpetremann:mqtt-exporter:v1.9.0...4188334fbc51fc277bc50fd66c068482bde9829a.diff";
            hash = "sha256-XpOiXu3F66ftNokNknq9ogJJU8mdb8flwWO9EkT4SVk=";
          })
          (pkgs.fetchpatch {
            name = "Add `MQTT_PASSWORD_FILE` option";
            url = "https://github.com/kpetremann/mqtt-exporter/commit/2bd5f203ebf476e36ac1d41d5c34f04719bcc5ee.diff";
            hash = "sha256-IsU7PLuiOx2PaiuY2FSPmqUVXDTxIISLRAUH5snBtJ0=";
          })
        ];
      });
      # logLevel = "DEBUG";
      zigbee2MqttAvailability = true;
      mqttUsername = "mqtt-exporter";
      mqttAddress = services.mqtt.fqdn;
      mqttPort = 8883; # MQTTS
      mqttIgnoredTopics = [
        # There's a lot of noise under here. I don't think I care about any of it.
        "zigbee2mqtt/bridge/#"
      ];
    };

    scrapeConfigs = [
      {
        job_name = "mqtt";
        static_configs = [
          {
            targets = [ "localhost:${toString config.services.prometheus.exporters.mqtt.port}" ];
            labels.alert_if_down = "true";
          }
        ];
      }
    ];

    ruleFiles = [
      (pkgs.writeText "mqtt.rules" (
        builtins.toJSON {
          groups = [
            {
              name = "mqtt";
              rules = [
                {
                  alert = "LongTimeNoSee";
                  expr = "time() - (mqtt_last_seen / 1000) > 3h";
                  labels = {
                    severity = "error";
                    category = "zigbee";
                  };
                  annotations.summary = "Have not heard from {{ $labels.topic }} in a while";
                  annotations.grafana = "https://grafana.m/d/admf9zr/zigbee";
                }
                {
                  alert = "LongTimeNoChange";
                  expr = "changes(mqtt_temperature[3h]) == 0";
                  labels = {
                    severity = "error";
                    category = "zigbee";
                  };
                  annotations.summary = "Have not seen a temperature change from {{ $labels.topic }} in a while";
                  annotations.grafana = "https://grafana.m/d/admf9zr/zigbee";
                }
                {
                  alert = "ZigbeeDeviceGone";
                  expr = "mqtt_zigbee_availability == 0";
                  labels = {
                    severity = "error";
                    category = "zigbee";
                  };
                  annotations.summary = "Zigbee device {{ $labels.topic }} not available";
                  annotations.grafana = "https://grafana.m/d/admf9zr/zigbee";
                }
                {
                  alert = "LowBattery";
                  # Note: `mqtt_battery_state` is derived from enums. See `STATE_VALUES` below.
                  expr = "mqtt_battery < 25 or mqtt_battery_state < 25";
                  labels = {
                    severity = "warning";
                    category = "zigbee";
                  };
                  annotations.summary = "Zigbee device {{ $labels.topic }} is low on battery available";
                  annotations.grafana = "https://grafana.m/d/admf9zr/zigbee";
                }
                {
                  alert = "ChestFreezerTooWarm";
                  # Alert if the freezer goes above 5 Fahrenheit.
                  expr = ''1.8 * mqtt_temperature{topic="zigbee2mqtt_freezer_weather"} + 32 > 5'';
                  for = "5m";
                  labels = {
                    severity = "error";
                    category = "zigbee";
                  };
                  annotations.summary = "Chest freeze appears to be too warm";
                  annotations.grafana = "https://grafana.m/d/admf9zr/zigbee";
                }
              ];
            }
          ];
        }
      ))
    ];
  };

  # The default is to not deploy the password, but we need it to configure the service.
  # Note: this only works because we happen to be deploying this to the same
  # machine that provisions mqtt users. A more correct version of this would
  # probably involve something like Clan's inventory system.
  clan.core.vars.generators."mqtt-${mqttUsername}".files.password.deploy = true;

  systemd.services.prometheus-mqtt-exporter = {
    # mqtt-exporter environment variables are documented here:
    # <https://github.com/kpetremann/mqtt-exporter?tab=readme-ov-file#configuration>.
    environment = {
      MQTT_PASSWORD_FILE = "/run/credentials/${config.systemd.services.prometheus-mqtt-exporter.name}/${mqttPasswordKeyId}";
      MQTT_ENABLE_TLS = "True";
      MAX_METRICS = "0"; # Unlimited metrics.
      STATE_VALUES = lib.concatStringsSep "," (
        lib.mapAttrsToList (key: value: "${key}=${toString value}") {
          # This is a hack that might only apply to Tuya zigbee devices, which
          # report their battery as an enum rather than a percentage. Enum names are from
          # <https://github.com/Koenkk/zigbee-herdsman-converters/blob/v25.117.0/src/lib/tuya.ts#L354>.
          # I chose the values with the intention of having "low" trigger the `LowBattery` alert above.
          low = 20;
          medium = 50;
          high = 80;
        }
      );
    };

    serviceConfig.LoadCredential = [
      "${mqttPasswordKeyId}:${
        config.clan.core.vars.generators."mqtt-${mqttUsername}".files.password.path
      }"
    ];
  };
}
