{
  lib,
  config,
  pkgs,
  ...
}:

let
  ports.mqtt = 1883;
  ports.mqtts = 8883;
  # After adding a user to the list, get their password with:
  # ```console
  # $ clan vars get fflewddur mqtt-jfly/password
  # ```
  mqttUsers = [
    "jfly"
    "home-assistant"
    "strider"
    "aragorn"
    "elfstone"
    "zigbee2mqtt"

    ### Light switches
    # See
    # ~/sync/jfly/notes/2025-07-10-costco-feit-switches-running-openbeken.md
    # for notes on how to provision new light switches.
    "pelydryn-dining-north"
    "pelydryn-dining-south"
    # "pelydryn-fireplace"
    # "pelydryn-kitchen-north"
    # "pelydryn-kitchen-south"
    # "pelydryn-living-room-east"
    # "pelydryn-living-room-south"
    "pelydryn-north-bathroom"
    "pelydryn-northeast-bedroom"
    # "pelydryn-northwest-bedroom"
    # "pelydryn-south-bathroom"
    # "pelydryn-south-bedroom-north"
    # "pelydryn-south-bedroom-south"
  ];

  # Generate an attrset suitable for passing to `services.mosquitto.listeners.*.users`.
  # Like this:
  #
  # ```nix
  # {
  #   jfly.hashedPasswordFile = config.clan.core.vars.generators.mqtt-jfly.files."password.hashed".path;
  #   ...
  # };
  # ```
  mqttListenerUsers = lib.pipe mqttUsers [
    (map (
      userName:
      (lib.nameValuePair userName {
        hashedPasswordFile =
          config.clan.core.vars.generators."mqtt-${userName}".files."password.hashed".path;
      })
    ))
    lib.listToAttrs
  ];

  mqttPwGenerators = lib.pipe mqttUsers [
    (map (
      userName:
      (lib.nameValuePair "mqtt-${userName}" {
        files."password".deploy = userName == "zigbee2mqtt"; # TODO: port to clan's inventory system and put this in machines/fflewddur/home-assistant/zigbee2mqtt.nix instead.
        files."password.hashed" = { };
        runtimeInputs = with pkgs; [
          coreutils
          gnused
          mosquitto
          xkcdpass
        ];
        script = ''
          # Generate a password.
          xkcdpass --numwords 4 --delimiter - | tr -d '\n' > $out/password

          # Generate a file of the form USERNAME:<hashedpw>.
          touch ./username-colon-hashedpw
          chmod 0700 ./username-colon-hashedpw
          mosquitto_passwd -b ./username-colon-hashedpw "USERNAME" $(< $out/password)

          # Extract just the hashedpw from the file and save that.
          sed 's/^USERNAME://' ./username-colon-hashedpw > $out/password.hashed
        '';
      })
    ))
    lib.listToAttrs
  ];
in
{
  # Keep this in sync with `mqtt.ec` in `routers/strider/files/etc/config/dhcp`
  # and Allow-MQTT* rules in `routers/strider/files/etc/config/firewall`.

  # Note that we use nginx to generate a cert for MQTT because nginx is capable
  # of passing the "host a file" HTTP challenge.
  security.acme.certs."mqtt.mm".reloadServices = [ "mosquitto.service" ];
  services.data-mesher.settings.host.names = [ "mqtt" ];
  services.nginx.virtualHosts."mqtt.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      recommendedProxySettings = true;
      extraConfig = ''
        add_header Content-Type text/plain;
        return 200 "There's a MQTT server here at :${toString ports.mqtt} and a MQTTS server at :${toString ports.mqtts}";
      '';
    };
  };

  # TODO: port HA to use MQTTS. I cannot get it to work. See
  # <https://github.com/home-assistant/core/issues/130643>
  clan.core.vars.generators = mqttPwGenerators;
  systemd.services.mosquitto.serviceConfig = {
    LoadCredential = [
      "cert.pem:${config.security.acme.certs."mqtt.mm".directory}/cert.pem"
      "key.pem:${config.security.acme.certs."mqtt.mm".directory}/key.pem"
    ];
  };
  services.mosquitto = {
    enable = true;
    # logType = [ "all" ]; # debug
    listeners = [
      {
        port = ports.mqtt;
        # Allow all users all access. Ideally we'd have finer grained ACLs.
        acl = [ "pattern readwrite #" ];
        users = mqttListenerUsers;
      }
      {
        port = ports.mqtts;
        settings = {
          keyfile = "/run/credentials/mosquitto.service/key.pem";
          certfile = "/run/credentials/mosquitto.service/cert.pem";
        };
        # Allow all users all access. Ideally we'd have finer grained ACLs.
        acl = [ "pattern readwrite #" ];
        users = mqttListenerUsers;
      }
    ];
  };
  networking.firewall.allowedTCPPorts = builtins.attrValues ports;
}
