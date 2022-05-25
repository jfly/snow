### Bluetooth
AddPackage --foreign bluez-hcitool # deprecated rfcomm tool from bluez
AddPackage blueman # GTK+ Bluetooth Manager
AddPackage bluez # Daemons for the bluetooth protocol stack
AddPackage bluez-utils # Development and debugging utilities for the bluetooth protocol stack
# Auto power-on bluetooth after boot.
# From https://wiki.archlinux.org/title/Bluetooth#Auto_power-on_after_boot
f="$(GetPackageOriginalFile bluez /etc/bluetooth/main.conf)"
sed -i 's/#AutoEnable=false/AutoEnable=true/' "$f"

# Start services
CreateLink /etc/systemd/system/bluetooth.target.wants/bluetooth.service /usr/lib/systemd/system/bluetooth.service
CreateLink /etc/systemd/system/dbus-org.bluez.service /usr/lib/systemd/system/bluetooth.service

# Ignore various files
IgnorePath '/var/lib/bluetooth/*'
IgnorePath '/var/lib/blueman/network.state'
