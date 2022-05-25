# jfly/dotfiles
I'm using the excellent [dotbot](https://github.com/anishathalye/dotbot).

See instructions on [this Google Doc](https://docs.google.com/document/d/1Ji1dfnQxlb9KJGmVin4W6oAqN4-SWokSlXGYumss74M/edit#heading=h.1gvhtuttse8f).

## Pre-install (if dual booting with Windows)
  - Windows
    - Disable hibernation in Windows (`powercfg /hibernate on`)
    - Resize Windows partition with Disk Management. (Sometimes this gets tricky with immovable files over in Windows. Forcing a defrag can help, but there are some system files that defrag won't move, and you'll need to move them yourself).
    - Set Windows to use UTC hardware clock time ([instructions from here](https://wiki.archlinux.org/index.php/time#UTC_in_Windows)): `reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /d 1 /t REG_QWORD /f`
  - UEFI/Secure Boot
    - In order to boot from the Arch USB, you will need to disable Secure Boot in the BIOS security tab.
    - Then, you can install a bootloader and set up Secure Boot. I have had good luck with rEFInd + shim.
        - [rEFInd bootloader](https://wiki.archlinux.org/index.php/REFInd). You might want to restyle rEFInd by adding a theme such [rEFInd-minimal-black-flat](https://github.com/dnaf/rEFInd-minimal-black-flat). I also changed `timeout` in `/boot/EFI/refind/refind.conf` to 5 seconds, and added `default_selection Linux`.
        - Install [shim-signed](https://aur.archlinux.org/packages/shim-signed/) and `sbsigntools`
        - `refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys`
        - `# sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output /boot/vmlinuz-linux /boot/vmlinuz-linux`
            warning: file-aligned section .text extends beyond end of file
            warning: checksum areas are greater than image size. Invalid section table?
            Signing Unsigned original image
        - If you want to add a boot entry for MokManager: `efibootmgr --disk /dev/nvme0n1 --part 1 --create --label "MokManager" --loader /EFI/refind/mmx64.efi`. Then re-run `refind-install` as above.
        - Once in MokManager add refind_local.cer to MoKList. refind_local.cer can be found inside a directory called keys in the rEFInd's installation directory, e.g. esp/EFI/refind/keys/refind_local.cer.

    - Enable virtualization in BIOS (otherwise you will see a message "kvm:disabled by bios")

## Directions for fresh Arch install
Follow the wiki! https://wiki.archlinux.org/index.php/installation_guide

- Set hostname: https://wiki.archlinux.org/index.php/installation_guide#Network_configuration
- `passwd` - Set the root password
- `pacman -S sudo && visudo` - Install and configure sudo.
- `useradd -m -G wheel -s /bin/bash jeremy && passwd jeremy && su jeremy` - Create user and set their password.
- `sudo pacman -S git && mkdir ~/gitting && cd ~/gitting && git clone https://github.com/jfly/dotfiles.git && cd dotfiles` - Checkout and cd into this repo!
- `./bootstrap-arch.sh` - Bootstrap Arch Linux installation, installing all dependencies. Make sure this command succeeds!
- If you want fancy fonts, you might want to look into https://aur.archlinux.org/packages/ttf-ms-win10/, which is a bit of an adventure to install.

## Swap
See https://wiki.archlinux.org/index.php/Swap#Swap_file_creation.

## Printer
When actually adding printer, use ppd file from <http://www.openprinting.org/printer/Brother/Brother-HL-2240>.

## Bluetooth
Note: Dualbooting with bluetooth is a *pain*. See:
https://unix.stackexchange.com/a/255510 and
http://console.systems/2014/09/how-to-pair-low-energy-le-bluetooth.html for
more details.
I've created this `dual-boot-bluetooth.py` script to identify discrepancies
between Linux and Windows, but it does not actually fix them yet. I'd like to
improve it so it can do that.

## Dropbox
- `dropbox` - Need to manually start dropbox and log in.
