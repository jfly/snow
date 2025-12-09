{ pkgs, config, ... }:
{
  # After generating, fetch the value and create a sambda user with the credentials:
  # ```console
  # $ clan vars get dallben dallben-samba-credentials/credentials
  # $ ssh fflewddur sudo smbpasswd -a dallben
  # ```
  clan.core.vars.generators.dallben-samba-credentials = {
    files.credentials = { };
    runtimeInputs = with pkgs; [
      xkcdpass
    ];
    script = ''
      # The format of the `credentials` file is specified in `man 8
      # mount.cifs`. Search for "credentials=filename".
      echo "username=dallben" >> $out/credentials
      pass=$(xkcdpass --numwords 4 --delimiter - | tr -d '\n')
      echo "password=$pass" >> $out/credentials
    '';
  };

  fileSystems."/mnt/media" = {
    device = "//fflewddur.ec/media-writer";
    fsType = "cifs";
    options =
      let
        credsPath = config.clan.core.vars.generators.dallben-samba-credentials.files."credentials".path;
      in
      [
        "x-systemd.automount"
        "noauto"
        "credentials=${credsPath}"
        "gid=${toString config.users.groups.media.gid}"
        "file_mode=0660" # rw for user and group.
        "dir_mode=0770" # rwx for user and group.
      ];
  };
}
