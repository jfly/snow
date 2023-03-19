# snow

Short for snowdon, the street on which I started playing around with Nix.

# deploy

To deploy all machines:

    ./deploy '*'

To deploy one machine:

    ./deploy 'dallben'

# live usb

To build a live usb:

    tools/build-portable-usb.sh 'pattern'

And follow the instructions it prints about how to copy this to a usb drive.

# sd card for raspberry pi

To build a sd card for a raspberry pi:

    tools/build-rpi-sdcard.sh 'kent'
