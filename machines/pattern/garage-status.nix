{
  inputs',
  config,
  pkgs,
  ...
}:

let
  inherit (config.snow) services;

  on-air = inputs'.on-air.packages.default;
in
{
  # TODO: port machines/fflewddur/home-assistant/mqtt.nix to clan's inventory
  # system, and combine this with the creation of the user.
  clan.core.vars.generators.mosquitto = {
    files."username" = {
      secret = false;
    };
    files."password" = {
      owner = "jeremy";
    };
    prompts.username = {
      description = "Username for ${services.mqtt.fqdn}";
      type = "line";
    };
    prompts.password = {
      description = "Password for ${services.mqtt.fqdn}";
      type = "hidden";
    };
    runtimeInputs = with pkgs; [
      coreutils
    ];
    script = ''
      cp $prompts/username $out/username
      cp $prompts/password $out/password
    '';
  };

  systemd.user.services.on-air = {
    enable = true;
    description = "on-air";

    wantedBy = [ "location-garageman.target" ];
    partOf = [ "location-garageman.target" ];

    script = ''
      ${on-air}/bin/on-air mqtt \
        --broker ${services.mqtt.base_url} \
        --username $(< ${config.clan.core.vars.generators.mosquitto.files."username".path}) \
        --password-file ${config.clan.core.vars.generators.mosquitto.files."password".path} \
        --device-name ${config.networking.hostName} \
        --poll-seconds 1
    '';
    serviceConfig = {
      Type = "simple";
      Restart = "always";
    };
  };
}
