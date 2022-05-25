### Boot
AddPackage efibootmgr # Linux user-space application to modify the EFI Boot Manager
AddPackage refind # An EFI boot manager
IgnorePath '/boot/*'
IgnorePath '/etc/refind.d/keys/refind_local.cer'
IgnorePath '/etc/refind.d/keys/refind_local.crt'
IgnorePath '/etc/refind.d/keys/refind_local.key'
cat > "$(CreateFile /etc/pacman.d/hooks/99-secureboot.hook)" <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux

[Action]
Description = Signing Kernel for SecureBoot
When = PostTransaction
Exec = /usr/bin/sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output /boot/vmlinuz-linux /boot/vmlinuz-linux
Depends = sbsigntools
EOF

### Full disk encryption
AddPackage --foreign shim-signed # Initial UEFI bootloader that handles chaining to a trusted full bootloader under secure boot environments.
AddPackage sbsigntools # Tools to add signatures to EFI binaries and Drivers
AddPackage cryptsetup # Userspace setup tool for transparent encryption of block devices using dm-crypt

### Core
AddPackage linux # The Linux kernel and modules
AddPackage linux-headers # Headers and scripts for building modules for the Linux kernel
IgnorePath '/usr/lib/modules/*'
IgnorePath '/var/lib/dkms/*'
AddPackage linux-firmware # Firmware files for Linux
AddPackage base # Minimal package set to define a basic Arch Linux installation
AddPackage intel-ucode # Microcode update files for Intel CPUs
AddPackage squashfs-tools # Tools for squashfs, a highly compressed read-only filesystem for Linux.
AddPackage util-linux # Miscellaneous system utilities for Linux
AddPackage filesystem # Base Arch Linux files
IgnorePath '/var/tmp/*' # https://www.pathname.com/fhs/pub/fhs-2.3.html#VARTMPTEMPORARYFILESPRESERVEDBETWEE

### mkinitcpio
IgnorePath '/etc/mkinitcpio.d/linux.preset' # https://wiki.archlinux.org/title/mkinitcpio#Automated_generation
mkinitcpio_conf="$(GetPackageOriginalFile mkinitcpio /etc/mkinitcpio.conf)"
# This is to enable reading a decrypt key from a usb drive during boot.
# See https://docs.google.com/document/d/1Ji1dfnQxlb9KJGmVin4W6oAqN4-SWokSlXGYumss74M/edit#bookmark=id.v5j76ck5xr48.
sed -i "s/^MODULES=.*/MODULES=(vfat)/" "$mkinitcpio_conf"
# Add the encrypt hook.
sed -i "s/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/" "$mkinitcpio_conf"

### Laptop
AddPackage acpi # Client for battery, power, and thermal readings
AddPackage acpid # A daemon for delivering ACPI power management events with netlink support
AddPackage --foreign laptop-mode-tools # Power Savings tool for Linux
CreateLink /etc/systemd/system/multi-user.target.wants/laptop-mode.service /usr/lib/systemd/system/laptop-mode.service

### Logging
IgnorePath '/var/log/*'

### Timezone
# https://wiki.archlinux.org/index.php/installation_guide#Time_zone
CreateLink /etc/localtime /usr/share/zoneinfo/America/Los_Angeles

### Locale
locale_gen=$(GetPackageOriginalFile glibc /etc/locale.gen)
function EnableLocale() {
    local locale="$1"
    if ! grep "#${locale}" "${locale_gen}" > /dev/null; then
        FatalError "Unrecognized locale: '${locale}'"
    fi
    sed -i "s/#${locale}/${locale}/" "${locale_gen}"
}
EnableLocale "en_US.UTF-8 UTF-8"
cat > "$(CreateFile /etc/locale.conf)" <<EOF
LANG=en_US.UTF-8
EOF
IgnorePath '/usr/lib/locale/locale-archive' # https://man7.org/linux/man-pages/man1/localedef.1.html

### Users/shadow
IgnorePath '/etc/shells'
IgnorePath '/etc/.pwd.lock' # https://dailystuff.nl/blog/the-hunt-for-etc-pwd-lock/
IgnorePath '/etc/gshadow'
IgnorePath '/etc/gshadow-'
IgnorePath '/etc/shadow'
IgnorePath '/etc/shadow-'
IgnorePath '/etc/passwd'
IgnorePath '/etc/passwd-'
IgnorePath '/etc/group'
IgnorePath '/etc/group-'

### sudo
AddPackage sudo # Give certain users the ability to run some commands as root
cat > "$(CreateFile /etc/sudoers.d/00_nopasswd)" <<EOF
# Allow members of group wheel to execute any command without having to enter a
# password.
%wheel ALL=(ALL) NOPASSWD: ALL
EOF

### swap
IgnorePath '/swapfile'

### Misc ignore
IgnorePath '/etc/hostname'
IgnorePath '/etc/adjtime'
IgnorePath '/usr/share/info/dir' # Index of all the info files. https://bbs.archlinux.org/viewtopic.php?id=55268
IgnorePath '/etc/ld.so.cache' # "File containing an ordered list of libraries found in the directories specified in /etc/ld.so.conf, as well as those found in the trusted directories."
IgnorePath '/etc/xml/catalog' # This comes from libxml2, which a number of packages depend on. http://xmlsoft.org/catalog.html

### Console
# Use a larger font.
cat > "$(CreateFile /etc/vconsole.conf)" <<EOF
FONT=LatGrkCyr-12x22
EOF
