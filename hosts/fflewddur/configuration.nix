{ inputs, flake, ... }:

let identities = flake.lib.identities;
in
{
  imports =
    [
      ./boot.nix
      ./network.nix
      ./nas.nix
      ./binary-cache.nix
      inputs.agenix.nixosModules.default
      inputs.agenix-rooter.nixosModules.default
    ];

  age.rooter.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBu1H1RFGjmzpUncYWUGwCDcQPVfgAxH4S2yYPt46a/5";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  networking.hostName = "fflewddur";
  # Disable the firewall. I'm not used to having one, and we're behind a NAT anyways...
  networking.firewall.enable = false;

  # i18n stuff
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  programs.ssh.extraConfig = ''
    Host kent
        HostName kent.sc.jflei.com
        User kent
  '';

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [
      identities.jfly
      identities.rachel
    ];
    hashedPassword = "$6$qZbruBYDeCvoleSI$6Qn9rUHVvutADJ7kxK9efrPLnNiW1dXgrdjrwFKIH338mq8A8dIk/tv/QV/kwrylK1GJtMW6qBsEkcszOh4f11";
  };
}
