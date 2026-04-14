# fflewddur

Our primary NAS running on that old gaming PC James gave me forever ago.

## Bootstrapping

1. F12 while booting. Enter BIOS Setup > BIOS Features
   - Boot Mode Selection: UEFI only
   - LAN PXE Boot Option ROM: Disabled
   - Storage Boot Option Control: UEFI Only
   - F10 to save and exit
2. Follow instructions in [`../README.md`](../README.md).
3. Allow various overlay network members: [machines/fflewddur/zerotier/static-peers.nix](machines/fflewddur/zerotier/static-peers.nix).
4. Set various passwords:
   - Samba:
     ```console
     $ sudo smbpasswd -a jfly
     $ sudo smbpasswd -a rachel
     ```

     `git grep smbpasswd` to find other users that must be created as well.

     TODO: manage this declaratively. See
     <https://github.com/kanidm/kanidm/issues/2627> and
     <https://github.com/lldap/lldap/issues/599> for promising options. If they don't
     work out, perhaps NixOS would accept a `passwordFile` option.
   - Unix:
     ```console
     $ sudo passwd jfly
     $ sudo passwd rachel
     ```

## Adding another drive

See [zfs/README.md](../../nixos-modules/zfs/README.md).
