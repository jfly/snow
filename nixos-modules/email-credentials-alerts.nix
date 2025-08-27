# TODO: explore if clan's inventory system would be better for handling this.
{ pkgs, ... }:
{
  clan.core.vars.generators.mail-alerts = {
    share = true;
    files."password" = { };
    files."password.bcrypt" = { };
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
      mkpasswd
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - | tr -d "\n" > $out/password
      mkpasswd --method=bcrypt --stdin < $out/password > $out/password.bcrypt
    '';
  };
}
