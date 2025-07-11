{
  inputs',
  config,
  pkgs,
  ...
}:

let
  on-air = inputs'.on-air.packages.default;
in
{
  # TODO: port mosquitto (iac/pulumi/app/mosquitto.py) to nix, and combine this
  # with the creation of the user.
  clan.core.vars.generators.mosquitto = {
    files."username" = {
      secret = false;
    };
    files."password" = {
      owner = "jeremy";
    };
    prompts.username = {
      description = "Username for mqtt.mm";
      type = "line";
    };
    prompts.password = {
      description = "Password for mqtt.mm";
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
        --broker mqtts://mqtt.mm \
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
