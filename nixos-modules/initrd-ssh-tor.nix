# References:
# https://github.com/Lassulus/superconfig/blob/master/2configs/tor-ssh.nix
# https://wiki.nixos.org/wiki/Remote_disk_unlocking
{
  flake,
  config,
  pkgs,
  ...
}:

let
  identities = flake.lib.identities;
  torRc = pkgs.writeText "tor.rc" ''
    DataDirectory /etc/tor
    SOCKSPort 127.0.0.1:9050 IsolateDestAddr
    SOCKSPort 127.0.0.1:9063
    HiddenServiceDir /etc/tor/onion/bootup
    HiddenServicePort 22 127.0.0.1:22
  '';
in
{
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 22;
    authorizedKeys = [
      identities.jfly
      identities.rachel
    ];
    hostKeys = [ config.clan.core.vars.generators.initrd-ssh.files."ssh_host_ed25519_key".path ];
  };
  boot.initrd.availableKernelModules = [
    "e1000"
    "e1000e"
  ];

  boot.initrd.secrets = {
    "/etc/tor/onion/bootup/hs_ed25519_secret_key" = (
      config.clan.core.vars.generators.tor-hidden-service.files."hs_ed25519_secret_key".path
    );
  };

  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.storePaths = [
    "${pkgs.tor}/bin/tor"
    torRc
  ];

  boot.initrd.systemd.services.tor = {
    wantedBy = [ "initrd.target" ];
    after = [
      "network.target"
      "initrd-nixos-copy-secrets.service"
    ];
    unitConfig.DefaultDependencies = false;

    path = [
      pkgs.coreutils
      pkgs.tor
    ];

    # Have to do this otherwise tor does not want to start.
    preStart = ''
      chmod -R 700 /etc/tor
    '';

    script = ''
      tor --torrc-file ${torRc}
    '';

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
    };
  };

  clan.core.vars.generators.tor-hidden-service = {
    files."hs_ed25519_secret_key" = { };
    files."hs_ed25519_public_key".secret = false;
    files."hostname".secret = false;
    runtimeInputs = with pkgs; [
      coreutils
      mkp224o
    ];
    script = ''
      mkp224o-donna snow -n 1 -d . -q -O addr
      mv "$(cat addr)"/hs_ed25519_secret_key "$out"/hs_ed25519_secret_key
      mv "$(cat addr)"/hs_ed25519_public_key "$out"/hs_ed25519_public_key
      <"$(cat addr)"/hostname tr -d '\n' > "$out"/hostname
    '';
  };

  clan.core.vars.generators.initrd-ssh = {
    files."ssh_host_ed25519_key" = { };
    files."ssh_host_ed25519_key.pub".secret = false;
    runtimeInputs = with pkgs; [
      coreutils
      openssh
    ];
    script = ''
      ssh-keygen -t ed25519 -N "" -f "$out/ssh_host_ed25519_key"
    '';
  };
}
