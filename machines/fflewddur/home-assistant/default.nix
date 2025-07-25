{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.snow) services;
in
{
  imports = [
    ./postgresql.nix
    ./mqtt.nix
    ./zigbee2mqtt.nix
  ];

  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      "co2signal"
      "roomba"
      "enphase_envoy"
      "esphome"
      "dlna_dmr"
    ];
    customComponents = with pkgs.home-assistant-custom-components; [
      hass-opensprinkler
    ];
    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      button-card
      opensprinkler-card
      restriction-card
      vacuum-card
    ];
    config = {
      # logger.default = "debug";
      http = {
        server_host = "::1";
        trusted_proxies = [ "::1" ];
        use_x_forwarded_for = true;
      };

      # https://www.home-assistant.io/integrations/homeassistant/
      homeassistant = {
        external_url = services.home-assistant.base_url;
        internal_url = services.home-assistant.base_url;
        unit_system = "us_customary";
      };

      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      # YAML mode is required in order to use `customLovelaceModules`.
      # I'm not ready to programmatically managed all my dashboards, though.
      # Fortunately, this seems to only require the "Overview" dashboard to be
      # YAML, other dashboards can still be managed in YAML or storage.
      lovelace.mode = "yaml";

      # Note about people and presence detection:
      # - We currently manage people/users imperatively through the HA ui:
      #   <https://home-assistant.m/config/person>.
      # - Configuring presence detection is a manual process involving 2 steps:
      #   - Edit a retained MQTT message to reconfigure wifi-presence to
      #     track devices by MAC:
      #     <https://github.com/awilliams/wifi-presence/issues/29>.
      #   - Add the resulting tracking devices (there should be one per AP) to
      #     the HA person on <https://home-assistant.m/config/person>.

      group = {
        everyone = {
          name = "Everyone";
          all = true;
          entities = [
            "person.jeremy"
            "person.rachel"
          ];
        };

        someone = {
          name = "Someone";
          all = false;
          entities = [
            "person.jeremy"
            "person.rachel"
          ];
        };
      };
      notify = [
        {
          platform = "group";
          name = "raremy";
          services = [
            { service = "jeremy"; }
            { service = "rachel"; }
          ];
        }
        {
          platform = "group";
          name = "jeremy";
          services = [ { service = "mobile_app_jflysolineage"; } ];
        }
        {
          platform = "group";
          name = "rachel";
          services = [ { service = "mobile_app_rachels_iphone_2"; } ];
        }
      ];

      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
      climate = [
        {
          unique_id = "snow_therm";
          platform = "generic_thermostat";
          name = "Snow Therm";
          heater = "switch.furnace";
          target_sensor = "sensor.northeast_bedroom_weather_temperature";
        }
      ];
      "command_line" = [
        {
          switch = {
            name = "Fan";
            unique_id = "fan";
            command_on = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/fan/on";
            command_off = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/fan/off";
            command_state = "${lib.getExe pkgs.curl} -s -X GET http://thermostat.ec/fan";
            value_template = ''{{ value_json.status == "on" }}'';
            icon = "mdi:fan";
          };
        }
        {
          switch = {
            name = "Furnace";
            unique_id = "furnace";
            command_on = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/furnace/on";
            command_off = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/furnace/off";
            command_state = "${lib.getExe pkgs.curl} -s -X GET http://thermostat.ec/furnace";
            value_template = ''{{ value_json.status == "on" }}'';
            icon = "mdi:fire";
          };
        }
        {
          switch =
            let
              toggleCommand = "${lib.getExe pkgs.curl} -s -X POST http://garage.ec/garage/toggle";
            in
            {
              name = "Garage";
              unique_id = "garage";
              command_on = toggleCommand;
              command_off = toggleCommand;
              command_state = "${lib.getExe pkgs.curl} -s -X GET http://garage.ec/garage";
              value_template = ''{{ value_json.status == "open" }}'';
              icon = ''
                {% if value_json.status == "open" %}
                  mdi:garage-open
                {% else %}
                  mdi:garage
                {% endif %}
              '';
            };
        }
      ];
    };
  };

  services.data-mesher.settings.host.names = [ services.home-assistant.sld ];
  services.nginx.virtualHosts.${services.home-assistant.fqdn} = {
    enableACME = true;
    forceSSL = true;
    extraConfig = ''
      proxy_buffering off;
      client_max_body_size 1024M;
    '';

    locations."/" = {
      recommendedProxySettings = true;
      proxyPass = "http://[::1]:${toString config.services.home-assistant.config.http.server_port}";
      proxyWebsockets = true;
    };
  };

  snow.backup.paths = [ config.services.home-assistant.configDir ];
}
