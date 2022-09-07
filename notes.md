URGGGGGGGGG NVIDIA: https://github.com/NixOS/nixpkgs/pull/165188

# TODO

- why is auto-login not working?
    - eliminate lightdm?
        - https://www.reddit.com/r/NixOS/comments/kr0j9v/im_very_confused_by_how_nixos_configures_xorg/
        - https://nixos.wiki/wiki/Using_X_without_a_Display_Manager
- why does mcg start up in such a weird way?
- media syncing:
    - /mnt/media
    - $HOME/wallpaper
    - move wallpaper to `/mnt/media` and add a symlink from ~/wallpaper -> /mnt/media/wallpaper
- secrets syncing:
    - private key
    - openssh
    - h4 vpn creds + passphrase
- h4 dev setup scripts
    - parse `.tool-versions` cleverness?
- flakes!
- REDO FROM SCRATCH

# scifi

- live usb?

# Notes

- urg, chromium is a nontrivial amount of setup
- base16 colorschemes weren't showing up: `git submodule init && git submodule update`
- woah external monitor brightness?? https://github.com/Hummer12007/brightnessctl#id-like-to-configure-the-brightness-of-an-external-monitor
