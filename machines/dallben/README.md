# `dallben`

Kodi running on NixOS.

## One-time setup

First, change some BIOS settings.

- Update BIOS. <https://wiki.archlinux.org/title/Intel_NUC> links to
  instructions for the "Visual BIOS", but we actually have the "Aptio
  BIOS":
  <https://www.intel.com/content/www/us/en/download/19485/bios-update-fncml357.html>
- F2 while booting to get into the BIOS
- Bios > Boot > Secure Boot > Secure Boot: Set to "Disabled"
- Bios > Performance > Cooling > Fan Control Mode: Set to "Quiet"
- Bios > Power > Power > After Power Failure: Set to "Power On"
- Bios > Advanced > Onboard Devices > HDMI CEC Control: Uncheck this box!
  (the Pulse-Eight adapter doesn't play nicely with this setting. See
  <https://github.com/Pulse-Eight/libcec/issues/445>.)

## Provision

1. Boot the machine with `jflyso`. F12 is the "select boot device" keypress.
2. `tools/fleet.py bootstrap --ssh jfly@jflyso dallben`
3. Make sure you've maxed out the volume with `alsamixer`: ssh to the machine,
   `sudo machinectl shell kodi@`, `alsamixer`.
4. Follow instructions in `nixos-modules/kodi-colusita/README.md` to finish
   bootstrapping.
