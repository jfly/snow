{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "fflewddur";
      runtimeInputs = [
        pkgs.freerdp
        pkgs.bitwarden-cli
      ];
      text = ''
        exec xfreerdp /v:fflewddur.ec /u:root "/p:$(bw get password fflewddur)" +dynamic-resolution
      '';
    })
  ];
}
