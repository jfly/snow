{ agenix, agenix-rooter }:
{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./nas.nix
      ./snow-backup.nix
      agenix.nixosModules.default
      agenix-rooter.nixosModules.default
    ];

  age.rooter = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLwEMWt15EGJ0Cpqu0VjoIyIOS3/qIcPhwRs8QgqG+r";
    generatedForHostDir = ../agenix-secrets/generated;
  };
  # TODO: consider getting rid of the ../agenix-secrets/ directory in favor of inlining the ascii armor text
  age.secrets.root-password.rooterFile = ../agenix-secrets/root/root-password.age;
  age.secrets.snow-backup-ssh-private-key.rooterFile = ../agenix-secrets/root/snow-backup-ssh-private-key.age;

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "fflam";
    # Disable the firewall. I'm just not used to having one, and we're behind a NAT anyways...
    firewall.enable = false;
  };

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnasT8sq608RevJt+DzyQF4ppsYzq7P0yBxxaI8EjYsC1LxzZHqZpxRmz3iHYyy3ax4wmoak4Qy/dIvIH6l8R5rCab9ZRWXWKp+EYnn2MNUGFMolo4ark1UUll1+Dzm8saNvIMC7Dr5FIlrlQoP9jKOIDFM+cVTUOqwwyFU+IedetjmT47mXVQ/QHgsdDXM5SwKdtM8YGWxrhA3n4WgwmWSYQZyoSxdiQkoatABOqSgPcmczyZ7HqwajgL81n/Jaj8D6KVfJsOm/PU4O5MO5GU4ya6CcQVMn/elBfZIIsh+5rUyNH2GxBdT7luvHwAiHs/jWoyWmH5mr+6IG6nKGmhv2kRPaEfpvHoGo/gM6j/PvW18nynlWkajPqsy5D/3+4UoSPwPNNn9T0yFauExq+AReb88/Ixez6YH2jIRmtlIV4njKL8c7qdULnTrj8SZnz3tMiWgmY86+w+LsDcWHVADINk9rlUPGZcmTD06GLXZjNkWOvC/deLgNnApWTPpwEbZWzugeOtl/busMKob7acH1/F7rRB9nMj4Dtayjvth9Lbf8UDu7Hi8147ADxJJpVwSIIEKAFDeBPGqiuVnYm66dxdvjRzLmdf5LAGh9wy88FpV9btWeNoKSQt5gy7de2zVyBjix4l17ZbYtGiKEvhHJlVg7H8AlP6m9BbA6aeYw==" ];
    passwordFile = config.age.secrets.root-password.path;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
