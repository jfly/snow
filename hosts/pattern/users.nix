{ self, config, lib, ... }:

let identities = self.lib.identities;
in
{
  options = {
    snow = {
      user = {
        name = lib.mkOption {
          type = lib.types.str;
          description = lib.mdDoc "User account name of the owner of this machine.";
        };
        uid = lib.mkOption {
          type = lib.types.int;
          description = lib.mdDoc "Account id for owner of this machine.";
        };
      };
    };
  };

  config = {
    users.users.${config.snow.user.name} = {
      uid = config.snow.user.uid;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "media"
        "dialout" # access /dev/ttyUSB* (such as for Arduino development)
      ];
      openssh.authorizedKeys.keys = [
        identities.jfly
      ];
    };
  };
}
