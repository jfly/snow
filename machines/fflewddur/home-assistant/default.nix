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
    ./thermostat.nix
  ];

  # Home Assistant doesn't honor the system certificate bundle:
  # <https://github.com/orgs/home-assistant/discussions/1209#discussioncomment-14800589>.
  # It instead uses `certifi`. Fortunately, `certifi` does honor this
  # environment variable.
  # I've asked on `#homeautomation:nixos.org` if there's a "more correct" fix for this.
  systemd.services.home-assistant.environment.NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
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
      opensprinkler
      frigate
    ];
    customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
      button-card
      opensprinkler-card
      restriction-card
      vacuum-card
      advanced-camera-card
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
        external_url = services.home-assistant.baseUrl;
        internal_url = services.home-assistant.baseUrl;
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
      #     ```console
      #     $ sd ha mqtt read-one wifi-presence/config
      #     $ sd ha mqtt publish --retain wifi-presence/config '{...}'
      #     ```
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
      command_line = [
        {
          switch = {
            name = "Fan";
            unique_id = "fan";
            command_on = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/fan/on";
            command_off = "${lib.getExe pkgs.curl} -s -X POST http://thermostat.ec/fan/off";
            command_state = "${lib.getExe pkgs.curl} -s -X GET http://thermostat.ec/fan";
            value_template = /* jinja */ ''{{ value_json.status == "on" }}'';
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

  snow.services.home-assistant = {
    proxyPass = "http://[::1]:${toString config.services.home-assistant.config.http.server_port}";
    nginxExtraConfig = ''
      proxy_buffering off;
      client_max_body_size 1024M;
    '';
  };

  snow.backup.paths = [ config.services.home-assistant.configDir ];
}
