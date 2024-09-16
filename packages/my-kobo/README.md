# Kobo

I have a [Kobo Libra 2](https://us.kobobooks.com/products/kobo-libra-2). I
switched over from the Kindle universe because I was tired of not having USB-C
(that's now a moot point), and I missed having physical page buttons. I'm quite
happy with the Kobo platform as it seems to be Linux based and quite
hackable.

I don't really like the default reading software, I use
[Plato](https://github.com/baskerville/plato/tree/master) instead.

[Quill-OS](https://github.com/Quill-OS/quill) looks ambitious and interesting, but
I have not checked it out yet.

## Setup

This is pretty manual. There's a lot of potential for automation here.

### Avoid creating a Kobo account

- English > Welcome to Kobo! > Don't have a Wi Fi network?
- Plug the device into USB. It should show up as a usb storage device.
  `sudo mount /dev/SOMETHING_HERE /mnt`
- Insert a bogus user into the database:
  ```
  $ sudo nix run nixpkgs#sqlite -- /mnt/.kobo/KoboReader.sqlite
  sqlite> insert into user (UserID, UserKey) values (1, 'empty');
  # (close sqlite)
  ```
- Unplug, you should be in!

### Install Plato

Following the instructions from
[plato/doc/GUIDE.md](https://github.com/baskerville/plato/blob/master/doc/GUIDE.md)
takes you to [One-Click Install Packages for KOReader & Plato - MobileRead
Forums](https://www.mobileread.com/forums/showthread.php?t=314220):

    cd "$(mktemp -d)"

    # download packages we want
    wget https://storage.gra.cloud.ovh.net/v1/AUTH_2ac4bfee353948ec8ea7fd1710574097/kfmon-pub/OCP-KOReader-v2023.10.zip
    wget https://storage.gra.cloud.ovh.net/v1/AUTH_2ac4bfee353948ec8ea7fd1710574097/kfmon-pub/OCP-Plato-0.9.40.zip

    # download and run installer
    wget https://storage.gra.cloud.ovh.net/v1/AUTH_2ac4bfee353948ec8ea7fd1710574097/kfmon-pub/kfm_nix_install.zip
    unzip kfm_nix_install.zip
    ./install.sh

Now configure Plato:

- Install dictionary for Plato (note: you may need to explicitly reload the
  dictionaries after this,
  https://github.com/baskerville/plato/issues/84#issuecomment-569347303)

  ```
  sudo rsync -avP $(nix build --no-link --print-out-paths nixpkgs#dictdDBs.wordnet)/share/dictd/ /mnt/kobo/.adds/plato/dictionaries/wn
  ```
- Customize keyboard
  ```
  sudo cp /mnt/.adds/plato/keyboard-layouts/english.json /mnt/kobo/.adds/plato/keyboard-layouts/jfly.json # edit + change name
  sudo vi /mnt/kobo/.adds/plato/Settings.toml  # set default layout to custom layout
  ```
- Install some fonts: `sudo nix run github:jfly/snow#my-kobo`
