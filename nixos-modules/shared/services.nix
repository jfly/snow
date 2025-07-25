{ config, lib, ... }:
{
  options.snow.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        local@{ name, ... }:
        {
          options = {
            sld = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            fqdn = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${local.config.sld}.${config.snow.tld}";
            };
            scheme = lib.mkOption {
              type = lib.types.str;
              default = "https";
            };
            base_url = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${local.config.scheme}://${local.config.fqdn}";
            };
          };
        }
      )
    );
  };

  config.snow.services = {
    audiobookshelf = { };
    budget = { };
    ca = { };
    home-assistant = { };
    immich = { };
    jellyfin = { };
    manman = { };
    media = { };
    mqtt.scheme = "mqtts";
    nextcloud = { };
    ospi = { };
    podhacks = { };
    step-ca.sld = "ca";
    vaultwarden = { };
    zigbee2mqtt = { };
  };
}
