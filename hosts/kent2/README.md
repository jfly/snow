# kent2

A Lenovo ThinkCentre M710q I impulse bought on ebay.

If it can play 4k content smoothly, it'll likely replace kent.

## Provision

1. Boot the machine with `jflyso`. F12 is the "select boot device" keypress.
2. `tools/fleet.py bootstrap --ssh jfly@jflyso kent2`
3. Set the default card profile to "Digital Stereo (HDMI) Output". (It defaults to the internal speaker):
   This is what I ran:
   ```
   pw-cli s 51 Profile '{ index: 4, save: true }'
   ```
   Cobbled together from instructions on
   <https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Migrate-PulseAudio#set-card-profile>.
   `pavucontrol` is way easier to debug this, though.
4. Follow instructions in `nixos-modules/kodi-colusita/README.md` to finish
   bootstrapping.
