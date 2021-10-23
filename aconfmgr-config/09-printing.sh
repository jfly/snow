### CUPS
AddPackage cups # The CUPS Printing System - daemon package
AddPackage --foreign xerox-workcentre-6515-6510 # Xerox WorkCentre 6515 / Phaser 6510 printer driver for CUPS
AddPackage hplip # Drivers for HP DeskJet, OfficeJet, Photosmart, Business Inkjet and some LaserJet

IgnorePath '/etc/printcap' # This file is automatically generated by cupsd.
IgnorePath '/etc/cups/subscriptions.conf' # Urg, https://github.com/apple/cups/issues/5313
IgnorePath '/etc/cups/classes.conf' # https://www.cups.org/doc/man-classes.conf.html
CopyFile /etc/cups/ppd/lloyd.ppd 640 '' cups
function PrinterConfFilter() {
    sed 's/Attribute marker-change-time .*/Attribute marker-change-time 1634170968/' | \
        sed 's/StateTime .*/StateTime 1634170968/' | \
        sed 's/Attribute marker-levels .*/Attribute marker-levels 95,96,96,96,-1,100,100,100,100/'
}
AddFileContentFilter '/etc/cups/printers.conf' PrinterConfFilter
CopyFile /etc/cups/printers.conf 600

# Wow, this is a mess of services.
CreateLink /etc/systemd/system/multi-user.target.wants/cups.path /usr/lib/systemd/system/cups.path
CreateLink /etc/systemd/system/multi-user.target.wants/org.cups.cupsd.path /usr/lib/systemd/system/org.cups.cupsd.path
CreateLink /etc/systemd/system/printer.target.wants/cups.service /usr/lib/systemd/system/cups.service
CreateLink /etc/systemd/system/printer.target.wants/org.cups.cupsd.service /usr/lib/systemd/system/org.cups.cupsd.service
CreateLink /etc/systemd/system/sockets.target.wants/cups.socket /usr/lib/systemd/system/cups.socket
CreateLink /etc/systemd/system/sockets.target.wants/org.cups.cupsd.socket /usr/lib/systemd/system/org.cups.cupsd.socket

# Ignore various files.
IgnorePath '/var/spool/*'
