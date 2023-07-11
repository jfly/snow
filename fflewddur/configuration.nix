{ config, lib, pkgs, ... }:

rec {
  imports =
    [
      ./boot.nix
      ./network.nix
      ./nas.nix
    ];

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
  services.xserver.layout = "us";

  # Enable ssh.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Generated with: tools/generate-ssh-keypair fflewddur
  system.activationScripts = {
    copySshKey =
      let
        keypair = {
          public = pkgs.writeText "id_ed25519.pub" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGRF0gjAFyts8BAxF09p2tzL6PQrGA30RVtmCuj71BNf fflewddur\n";
          private = pkgs.deage.storeFile {
            name = "id_ed25519";
            encrypted = ''
              -----BEGIN AGE ENCRYPTED FILE-----
              YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBjdTd3dkdDT2RYNWQyVktR
              SjJlaUtVb2piVjZTV0VJVTAxeVZDeUtGR0g0CmFrb1lBbkJhTnVvZ1F4alIyUzQ3
              NER5TzM4TlFhNHRvaFc3M0orUERjWmMKLS0tIFAyVWJNNzNyNzh4Znl6MlIvMWti
              cG1MV1hITDVCRzdROGlOMEJxSmZDS2cK9rtTlzPCQamZTwwjH5yUfisiVbilaX3v
              xNZJEuE60111WvqIZjOBxNzKu7zcgiPTRGOVg7kQwtK84GgZMKsVGWwrgBCae5Fn
              RgkihlcQP0TeCABRiD6XqZp9fbTzCfc98wdNhy6u9OjZ/Ssw5ikQvMHdgoGRr79n
              LoGr/cNuwYfcYs7EBZum0DMLiB/63DKIcnIrnU6TzTtKuk6D7GYnOBE9qDJdtt7M
              epoKEXtGUKPJFd1HBgacfo6D3n+efHPJJwVlEUlcrMiOEgBgS9MYHLn46lCNrHvu
              28WL3geGWZVMvy1AOjh0TTe+7ORwVrJUA2UEObJzSAarpsL+QJGAOVs4+Iz5Iso6
              TADEJ9IsJg72SwU1HuPhn0UnuEtf3EeNl6T7nObTMnxydOtz309nrh3O2UC89zsr
              iYy5ZK1/v9vbnVBfxd9oMztnnPGIPqKYC/ifELJfM1Bffl8dUzf52rnfomj9/IeM
              6sEzHg7i4tDa5OIPKgiT92DM2vHDW0E5y3rP56P8fsQzganKZPdjd0U7kfrLvgKA
              qbI8m3G5Tp9aIJN9cuJe1oCW7eTF3so=
              -----END AGE ENCRYPTED FILE-----
            '';
          };
        };
      in
      ''
        cp ${keypair.private} /root/.ssh/id_ed25519
        cp ${keypair.public} /root/.ssh/id_ed25519.pub
        chmod 0400 /root/.ssh/id_ed25519
      '';
  };

  programs.ssh.extraConfig = ''
    Host kent
        HostName kent.sc.jflei.com
        User kent
  '';

  # Allow ssh access as root user.
  users.users.root = {
    openssh.authorizedKeys.keys = [
      # Jeremy's public key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDnasT8sq608RevJt+DzyQF4ppsYzq7P0yBxxaI8EjYsC1LxzZHqZpxRmz3iHYyy3ax4wmoak4Qy/dIvIH6l8R5rCab9ZRWXWKp+EYnn2MNUGFMolo4ark1UUll1+Dzm8saNvIMC7Dr5FIlrlQoP9jKOIDFM+cVTUOqwwyFU+IedetjmT47mXVQ/QHgsdDXM5SwKdtM8YGWxrhA3n4WgwmWSYQZyoSxdiQkoatABOqSgPcmczyZ7HqwajgL81n/Jaj8D6KVfJsOm/PU4O5MO5GU4ya6CcQVMn/elBfZIIsh+5rUyNH2GxBdT7luvHwAiHs/jWoyWmH5mr+6IG6nKGmhv2kRPaEfpvHoGo/gM6j/PvW18nynlWkajPqsy5D/3+4UoSPwPNNn9T0yFauExq+AReb88/Ixez6YH2jIRmtlIV4njKL8c7qdULnTrj8SZnz3tMiWgmY86+w+LsDcWHVADINk9rlUPGZcmTD06GLXZjNkWOvC/deLgNnApWTPpwEbZWzugeOtl/busMKob7acH1/F7rRB9nMj4Dtayjvth9Lbf8UDu7Hi8147ADxJJpVwSIIEKAFDeBPGqiuVnYm66dxdvjRzLmdf5LAGh9wy88FpV9btWeNoKSQt5gy7de2zVyBjix4l17ZbYtGiKEvhHJlVg7H8AlP6m9BbA6aeYw=="
      # Rachel's public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmJtvfl3mYWXAc/NSvJhWVSAytn2nKCXxghn1kh/iQ5 rmeresman@gmail.com"
      # fflam's public key
      # TODO: actually share this configuration between the hosts
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHxw+hsi7OFBP9tN1S/8PErm/AHWxcyJXC2k6q+96jqa fflam"
    ];
    hashedPassword = "$6$qZbruBYDeCvoleSI$6Qn9rUHVvutADJ7kxK9efrPLnNiW1dXgrdjrwFKIH338mq8A8dIk/tv/QV/kwrylK1GJtMW6qBsEkcszOh4f11";
  };
}
