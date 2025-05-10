{ lib, ... }:

{
  # Enable sshd
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  # But do not let it autostart.
  systemd.services.sshd.wantedBy = lib.mkForce [ ];
}
