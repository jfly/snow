A Raspberry Pi 3B in San Clemente acting mostly as a print server.

## Bootstrapping

Simply: `tools/build-rpi-sdcard.sh kent` and follow the instructions to copy
the resulting `*.img` file onto a sdcard.

## Known issues

If you plug in an external drive, the machine won't boot. See
https://bugs.launchpad.net/ubuntu/+source/u-boot/+bug/1891817 and
https://lore.kernel.org/all/20220718174849.ygiyqhg2qjks3o4i@kalarepa.grzadka/
for details. I haven't found a workaround yet, so for now we're just not
booting the machine with any hard drive attached =(
