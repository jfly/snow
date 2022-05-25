### Network
AddPackage inetutils # A collection of common network programs
AddPackage network-manager-applet # Applet for managing network connections
AddPackage networkmanager-openvpn # NetworkManager VPN plugin for OpenVPN
AddPackage networkmanager-vpnc # NetworkManager VPN plugin for VPNC
AddPackage nmap # Utility for network discovery and security auditing
AddPackage net-tools # Configuration tools for Linux networking
AddPackage lsof # Lists open files for running Unix processes
AddPackage macchanger # A small utility to change your NIC's MAC address

### Wifi
AddPackage hostapd # IEEE 802.11 AP, IEEE 802.1X/WPA/WPA2/EAP/RADIUS Authenticator
AddPackage --foreign create_ap # A shell script to create a NATed/Bridged Software Access Point

### nss-mdns (Avahi hostname resolution)
AddPackage avahi nss-mdns # glibc plugin providing host name resolution via mDNS
# From https://wiki.archlinux.org/title/avahi#Hostname_resolution:
#   > change the hosts line to include mdns_minimal [NOTFOUND=return] before resolve and dns
f="$(GetPackageOriginalFile filesystem /etc/nsswitch.conf)"
sed -i 's/hosts: \(.*\) \(resolve .*\)/hosts: \1 mdns_minimal [NOTFOUND=return] \2/' "$f"
CreateLink /etc/systemd/system/multi-user.target.wants/avahi-daemon.service /usr/lib/systemd/system/avahi-daemon.service
CreateLink /etc/systemd/system/sockets.target.wants/avahi-daemon.socket /usr/lib/systemd/system/avahi-daemon.socket
CreateLink /etc/systemd/system/dbus-org.freedesktop.Avahi.service /usr/lib/systemd/system/avahi-daemon.service

### SSH
AddPackage openssh # Premier connectivity tool for remote login with the SSH protocol
IgnorePath '/etc/ssh/ssh_host_*'

### Certificates
AddPackage openssl-1.0 # The Open Source toolkit for Secure Sockets Layer and Transport Layer Security
AddPackage ca-certificates-utils
IgnorePath '/etc/ca-certificates/extracted/*'
IgnorePath '/etc/ssl/certs/*'

### Samba
AddPackage samba # SMB Fileserver and AD Domain server
IgnorePath '/var/lib/samba/private/msg.sock/*'

### Start misc services.
CreateLink /etc/systemd/system/dbus-org.freedesktop.NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
CreateLink /etc/systemd/system/multi-user.target.wants/NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
CreateLink /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service /usr/lib/systemd/system/NetworkManager-wait-online.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service

### Ignore various files
IgnorePath '/var/lib/systemd/rfkill/*'
IgnorePath '/etc/resolv.conf'
IgnorePath '/etc/resolv.conf.bak'
IgnorePath '/etc/dhcpcd.duid'
IgnorePath '/etc/dhcpcd.secret'
IgnorePath '/var/lib/misc/dnsmasq.leases'
IgnorePath '/etc/openvpn/*'
IgnorePath '/var/lib/NetworkManager/*'
IgnorePath '/etc/NetworkManager/system-connections/*'

### /etc/hosts
f="$(GetPackageOriginalFile filesystem /etc/hosts)"
{
    echo ""
    echo "127.0.0.1 localhost.localdomain localhost"
    echo "::1 localhost.localdomain localhost"
} >> "$f"
if [[ "$HOSTNAME" == dalinar ]]; then
	echo '127.0.1.1 dalinar.localdomain dalinar' >> "$f"
fi
