Playing around with NixOS

# Provisioning an Intel NUC

https://docs.google.com/document/d/1LtwhNzlWBPv61b5ysdFDaDuw3bote0nc9ObSiC2ZJ7s/

## BIOS setup ##
    - F2 while booting to get into the BIOS
    - Bios > Boot > Secure Boot > Secure Boot: Set to "Disabled"
    - Bios > Performance > Cooling > Fan Control Mode: Set to "Quiet"
    - Bios > Power > Power > After Power Failure: Set to "Power On"
    - TODO: update bios! https://wiki.archlinux.org/title/Intel_NUC

## Set up USB drive ##
    wget https://channels.nixos.org/nixos-21.11/latest-nixos-minimal-x86_64-linux.iso
    sudo dd bs=4M if=./latest-nixos-minimal-x86_64-linux.iso of=/dev/sda conv=fsync oflag=direct status=progress

## Boot from USB w/ ethernet connected ##
    https://nixos.org/manual/nixos/stable/index.html#sec-installation-booting

    # On new nixos machine
    $ mkdir ~/.ssh
    $ curl https://github.com/jfly.keys > ~/.ssh/authorized_keys
    # At this point, you can continue from laptop by doing `ssh nixos@nixos`.
    # Partition
    $ sudo su
    $ parted /dev/nvme0n1 -- mklabel gpt
    $ parted /dev/nvme0n1 -- mkpart primary 512MiB -0
    $ parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
    $ parted /dev/nvme0n1 -- set 2 esp on
    # Format
    $ mkfs.ext4 -L nixos /dev/nvme0n1p1
    $ mkfs.fat -F 32 -n boot /dev/nvme0n1p2
    # Install
    $ mount /dev/disk/by-label/nixos /mnt
    $ mount /dev/disk/by-label/boot /mnt/boot
    $ nixos-generate-config --root /mnt
    $ nixos-install
    $ reboot

## Actually deploy these changes (first time) ##

I don't want to take the time to figure out a good secrets management solution,
so we're doing something simple right now:

    git clone <this repo> /etc/nixos
    cd /etc/nixos
    cp secrets.nix.example secrets.nix
    # edit secrets.nix!

This relies upon some not-yet-upstreamed changes to nixpkgs. Until they are
upstreamed, deploy them with a custom checkout of nixpkgs like so:

    git clone ??? ~/nixpkgs
    sudo nixos-rebuild -I nixpkgs=~/nixpkgs/ switch

## Actually deploy these changes (from personal dev machine) ##

Editing files remotely can get old fast. There's a `mount` script that makes it
easy to mount a remote machine's `/etc/nixos` and get to work on it.

    tools/mount.sh
    cd dallben2/
    ssh dallben2 ./snix.sh

# TODO
    + passwordless sudo?
    + nfs mount
    + hw acceleration
    + audio???
        + i'm on kernel 5.10.81. looks like this might be addressed in 5.14+?
          + https://github.com/clearlinux/distribution/issues/2396
          + https://github.com/torvalds/linux/commit/e81d71e343c6c62cf323042caed4b7ca049deda5
    + install parsec
        + stop_parsec.sh
    + configure kodi
        + userdata
            + advancedsettings.xml
            + sources.xml
            + keymaps/custom.xml: to start parsec!
        + addons
            + .kodi/addons/script.parsec/
    + .kodi/addons/service.autoreceiver/
        + https://github.com/wuub/rxv
        + reciever-on.py
        + tv-on.py
    + not needed?
        + auto-audio.sh
        + get-audio.sh
        + set-audio.sh
        + run_parsec.sh
        + {tv,reciever}-off.sh
        + Yatse gives an error about Event Server not working?
            + gonna just ignore this. it doesn't seem to affect anything?
    + bluetooth
    + remove secrets from advancedsettings.xml
    + overlay/storage/.kodi/userdata/addon_data/skin.estuary/settings.xml

    - tubecast
        - out/storage/.kodi/userdata/addon_data/plugin.video.youtube/api_keys.json
        - tubed
            - remove?
            - grep privacy.policy.accepted ~/.kodi/ -r: /home/dallben/.kodi/userdata/addon_data/plugin.video.tubed/settings.xml:    <setting id="privacy.policy.accepted">10222020</setting>

    - deploy
        - change hostname to "dallben"
        - replace old pi
        - pair bluetooth controllers
        - test stopping parsec when inside gurgi: ssh config

    - more secrets/polish
        - parsec login secret ($PARSEC_USER_BIN_BASE64 in clark:/mtn/media/.build-secrets/jpi-kodi.secrets) ~/.parsec/user.bin
        - bluetooth connection secrets?
    - cleanup
        - DRY up username "dallben" throughout various nix files. maybe introduce some concept of a "main"/"admin" user?
        - DRY up devicename in advancedsettings.xml
    - TODO: upstream
        - contribute back to https://github.com/DarthPJB/parsec-gaming-nix/blob/main/default.nix
        - webui broken: https://github.com/NixOS/nixpkgs/issues/145116
            - wrapper symlinks are preventing us from getting past this block of code: https://github.com/xbmc/xbmc/blob/4ac445c4a9f3080895bfcc34e7115e2de5b66d22/xbmc/utils/FileUtils.cpp#L299-L319
                - i've worked around this for now by hacking on pkgs/applications/video/kodi/wrapper.nix
        - auto enable relevant plugins.
            - see custom nixpkgs: pkgs/applications/video/kodi/wrapper.nix. can we upstream this?
            - i think we can do better by making these look like "system" addons. this file looks very relevant: /nix/store/1c9asw9zw87f74vsdhl4yanwcj5b3i0n-kodi-19.3-env/share/kodi/system/addon-manifest.xml (see xbmc/addons/AddonManager.cpp and xbmc/addons/AddonDatabase.cpp)
    - version control all of this
        - cleanup jpi/kodi. reuse that space? urg, jpi will become misnamed :cry:
    - Lastly: do it all again from scratch
