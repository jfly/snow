# TODO: explore if clan's inventory system would be better for handling this.
{ pkgs, ... }:
{
  clan.core.vars.generators.fflewddur-fflam-backup-ssh = {
    share = true;
    files."key" = { };
    files."key.pub".secret = false;
    runtimeInputs = with pkgs; [
      coreutils
      openssh
    ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f "$out/key"
    '';
  };
}
