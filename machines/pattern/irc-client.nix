{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.snow) services;
  getPass = pkgs.writeShellApplication {
    name = "get-senpai-pass";
    text = ''
      cat ${config.clan.core.vars.generators.jfly-irc-pass.files.password.path}
    '';
  };
  configFile = pkgs.writeTextFile {
    name = "senpai.cfg";
    text = ''
      address "${services.irc.fqdn}"
      nickname "jfly"
      password-cmd "${lib.getExe getPass}"
    '';
  };
in
{
  # After being generated, set this password in soju:
  # ```console
  # $ clan vars get pattern jfly-irc-pass/password
  # fflewddur# sojudb change-password <soju username>
  # fflewddur# systemctl restart soju
  # ```
  clan.core.vars.generators.jfly-irc-pass = {
    files."password".owner = config.snow.user.name;
    runtimeInputs = with pkgs; [
      coreutils
      xkcdpass
      mkpasswd
    ];
    script = ''
      xkcdpass --numwords 4 --delimiter - | tr -d "\n" > $out/password
    '';
  };

  environment.systemPackages = [
    (pkgs.symlinkJoin {
      inherit (pkgs.senpai) name;
      paths = [ pkgs.senpai ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/senpai \
          --add-flags "-config ${configFile}"
      '';
    })
  ];
}
