# `kent`

A HTPC running on a ThinkCentre M92p in San Clemente.

## Provision

1. Boot the machine with `jflyso`. F12 is the "select boot device" keypress.
2. `tools/fleet.py bootstrap --ssh jfly@jflyso kent`
3. Set the default card profile to "Digital Stereo (HDMI) Output". (It defaults to the internal speaker):
   This is what I ran (via `sudo machinectl shell kodi@`):
   ```
   pw-cli s 51 Profile '{ index: 4, save: true }'
   ```
   Cobbled together from instructions on
   <https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Migrate-PulseAudio#set-card-profile>.
   `pavucontrol` is way easier to debug this, though.

   I also had to run `alsamixer` to crank the volume to 100%.
4. Follow instructions in `nixos-modules/kodi-colusita/README.md` to finish
   bootstrapping.
