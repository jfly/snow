# Patterned off of https://wiki.nixos.org/wiki/Netboot

{
  flake,
  pixiecore,
  writeShellApplication,
}:

let
  sys = flake.nixosConfigurations.jflyso.extendModules {
    modules = [
      (
        { modulesPath, ... }:
        {
          imports = [ "${modulesPath}/installer/netboot/netboot-minimal.nix" ];
          # The default compression algorithm produces the smallest images, but takes a *while*.
          netboot.squashfsCompression = "gzip -Xcompression-level 1";
        }
      )
    ];
  };
  netbootBuild = sys.config.system.build;
in

writeShellApplication {
  name = "netboot-jflyso";

  runtimeInputs = [
    pixiecore
  ];

  text = ''
    exec pixiecore \
      boot ${netbootBuild.kernel}/bzImage ${netbootBuild.netbootRamdisk}/initrd \
      --cmdline "init=${netbootBuild.toplevel}/init loglevel=4" \
      --debug --dhcp-no-bind \
      --port 64172 --status-port 64172 "$@"
  '';
}
