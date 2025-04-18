# References:
# https://github.com/Lassulus/superconfig/blob/master/2configs/tor-ssh.nix
# https://wiki.nixos.org/wiki/Remote_disk_unlocking
{
  flake,
  lib,
  config,
  pkgs,
  ...
}:

let
  identities = flake.lib.identities;
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
    # >>> cryptsetup-askpass <<<
    # >>> TODO <<<: generated with `OUT_DIR=generated-secrets nix run .#nixosConfigurations.locked-vm.config.system.build.generate-vars`
    hostKeys = [ config.vars.generators.initrd-ssh.files."ssh_host_ed25519_key".path ];
    # <<< hostKeys = [ ../generated-secrets/secret/initrd-ssh/ssh_host_ed25519_key ]; # <<<
  };
  boot.initrd.availableKernelModules = [ "e1000e" ];

  boot.initrd.secrets = {
    "/etc/tor/onion/bootup/hs_ed25519_secret_key" = (
      lib.traceVal config.vars.generators.tor-hidden-service.files."hs_ed25519_secret_key".path
    );
    # <<< ../generated-secrets/secret/tor-hidden-service/hs_ed25519_secret_key;
  };

  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.tor}/bin/tor
  '';

  # Start tor during boot process.
  boot.initrd.network.postCommands =
    let
      torRc = pkgs.writeText "tor.rc" ''
        DataDirectory /etc/tor
        SOCKSPort 127.0.0.1:9050 IsolateDestAddr
        SOCKSPort 127.0.0.1:9063
        HiddenServiceDir /etc/tor/onion/bootup
        HiddenServicePort 22 127.0.0.1:22
      '';
    in
    ''
      echo "tor: preparing onion folder"
      # have to do this otherwise tor does not want to start
      chmod -R 700 /etc/tor

      echo "make sure localhost is up"
      ip a a 127.0.0.1/8 dev lo
      ip link set lo up

      echo "tor: starting tor"
      tor -f ${torRc} --verify-config
      tor -f ${torRc} &
    '';

  vars.generators.tor-hidden-service = {
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
      mv "$(cat addr)"/hostname "$out"/hostname
    '';
  };

  vars.generators.initrd-ssh = {
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
