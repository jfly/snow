# kent2

A Lenovo ThinkCentre M710q I impulse bought on ebay.

If it can play 4k content smoothly, it'll likely replace kent.

# Provision

1. Boot the machine with `jflyso`. F12 is the "select boot device" keypress.
2. `tools/fleet.py bootstrap --ssh jfly@jflyso kent2`
3. Follow instructions in `nixos-modules/kodi-colusita/README.md` to finish
   bootstrapping.
