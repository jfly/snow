{ agenix, agenix-rooter }:
{ config, lib, pkgs, ... }:

let identities = import ../shared/identities.nix;
in
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
    generatedForHostDir = ../agenix-rooter-reencrypted-secrets;
  };
  age.secrets.root-password.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBaU3NKZ3FScGdxN0w5MVJF
    MmI0TGtqRE5MaC8rVkFpYWNUL0k4L09sV1E0ClQvMW1JaXgwVHM1NHdETTZoQTFl
    Y1RPUVlxcWlqZHRoRU44V2JXbiszTDQKLS0tIGZWbmhySjVBdGxhbExhcDhtSzlh
    WW9mSUUxOTVpV0hSalI3TVlpRitmVlUKu4A/VOmigClvg+pF5pxxNtG95ulytp3y
    a2QEtmbB70jgywg9VeuqP0+j
    -----END AGE ENCRYPTED FILE-----
  '';
  age.secrets.snow-backup-ssh-private-key.rooterEncrypted = ''
    -----BEGIN AGE ENCRYPTED FILE-----
    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBqUVg2NnNBcHZCUWxBWGcy
    c052bWlBbkRMYnMzVVErbGtwVCt4emFzeWo0CnpQVDVvejc3bHJBMEY3cXhmSFZW
    TFBSNGFsTVNBcURvM1Q3RkdwQkpyMG8KLS0tIGhkS2RjSXFGdG96YnN3UU04b2Jp
    V0cvU0NBS24vWlU2VWFwWDlRQUFXaVEKTBBDx9ndVJyN595Yp3kB5Cr0kF6v03Qf
    iJm8pYzRbU8S+VSrHMVZ/gM+Tp87UifjSdLOMoZAHBvh+e/ANfFJzDb14it+7CKP
    oRXwQtcGqvqI6oEAACqN2VWSKmptPZ8yNXn3NMpoePa1lAkdqQvm6inUpdma1LkV
    jDt6bKO3Zdkkj9IvDYEFB40D+JvsUO32PA/84Ek9ojdQmdif2YskZYA3hgIynuA4
    zFA1nOh0hsr/6Mj/HGiAhSqorTk0veztpEsnyFHLNEXhaSnRWl9PGknl+pnGsQT7
    HoPe9N4iUiPOlx5sBQ5g1nqclcHNqpIo13MMbhZ+g5tdODp6eP07oLLe6rSr5y9G
    3NofZF55PxnH5eLoyiz5t6yOvY00rGHH1VDAE0w2UKcsR90lGdYRKZLmxsHB8Q+d
    lFq1QxVXk9ULixQQfJ1urzKS2RXlCLzzHyP62GjOw2FIYyLVA9k5VFCc2gpXZ1gO
    DDlYNZ6MdrBNdp1IQZ+CuruZRUjPboWuHTDJVEuuZ+zOhzxX/iqXoYw/aASnkEV8
    msY1i/Jqxay/kY8=
    -----END AGE ENCRYPTED FILE-----
  '';

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
    openssh.authorizedKeys.keys = [ identities.jfly ];
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
