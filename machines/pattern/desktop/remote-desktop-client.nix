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
        item=$(bw get item 69d659a4-55e2-4f23-af3d-80f10b81d0de)
        username=$(echo "$item" | jq --raw-output .login.username)
        password=$(echo "$item" | jq --raw-output .login.password)
        exec xfreerdp /v:fflewddur.m "/u:$username" "/p:$password" +dynamic-resolution
      '';
    })
  ];
}
