### systemd
# I'm not clear on where these empty folders come from, and if we should be
# creating them here or not.
CreateDir /var/lib/systemd/home
CreateDir /var/lib/systemd/linger
CreateDir /var/lib/systemd/pstore
IgnorePath '/var/lib/systemd/backlight/pci-0000:00:02.0:backlight:intel_backlight'
IgnorePath '/var/lib/systemd/backlight/platform-thinkpad_acpi:leds:tpacpi::kbd_backlight'
IgnorePath '/var/lib/systemd/catalog/database' # This file enumerates all logs including kernel, boot and application logs and provides required logs via journalctl utility. (https://itectec.com/ubuntu/ubuntu-where-are-all-the-major-log-files-located/)
IgnorePath '/var/lib/systemd/coredump'
IgnorePath '/var/lib/systemd/timers/stamp-*.timer' # systemd timer timestamps
IgnorePath '/var/lib/systemd/timesync/clock' # From https://wiki.archlinux.org/title/systemd-timesyncd: "The service writes to a local file /var/lib/systemd/timesync/clock with every synchronization. This location is hard-coded and cannot be changed. This may be problematic for running off read-only root partition or trying to minimize writes to an SD card."
IgnorePath '/var/lib/systemd/random-seed'
IgnorePath '/usr/lib/udev/hwdb.bin'  # https://www.freedesktop.org/software/systemd/man/hwdb.html
IgnorePath '/etc/os-release' # This file (actually, symlink) is created by systemd. See https://bbs.archlinux.org/viewtopic.php?id=251724.
IgnorePath '/var/lib/portables'  # Hard to find documented? https://bbs.archlinux.org/viewtopic.php?id=260291

# Start services.
CreateLink /etc/systemd/system/getty.target.wants/getty@tty1.service /usr/lib/systemd/system/getty@.service
CreateLink /etc/systemd/system/multi-user.target.wants/acpid.service /usr/lib/systemd/system/acpid.service
CreateLink /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.timesync1.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/user/sockets.target.wants/p11-kit-server.socket /usr/lib/systemd/user/p11-kit-server.socket

# Ignore various files.
IgnorePath '/etc/machine-id' # https://wiki.debian.org/MachineId
IgnorePath '/etc/.updated' # https://www.freedesktop.org/software/systemd/man/systemd-update-done.service.html
IgnorePath '/var/.updated' # https://www.freedesktop.org/software/systemd/man/systemd-update-done.service.html
IgnorePath '/var/lib/dbus/machine-id' # https://wiki.debian.org/MachineId
IgnorePath '/var/lib/machines' # https://www.freedesktop.org/software/systemd/man/machinectl.html
IgnorePath '/var/lib/private' # https://bbs.archlinux.org/viewtopic.php?id=241818 and https://0pointer.net/blog/dynamic-users-with-systemd.html
IgnorePath '/var/lib/logrotate.status'
IgnorePath '/var/lib/upower/history-*'
