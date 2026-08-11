# strongbad

An X1 Carbon (5th generation).

Pretty minimal COSMIC desktop environment. Most things are installed via Flatpak.

One time setup:

1. Open the COSMIC Store and enable some sources.
2. Clear the keyring passphrase. It's annoying with autologin (the unlock
   keyring popup just appears randomly when some application first tries to
   access the keyring, and often is hidden). We have FDE, and we don't run
   untrusted code, so it doesn't provide any value.
   - An alternative might be
     [`pam_fde_boot_pw`](https://github.com/NixOS/nixpkgs/pull/481342) (perhaps
     with `boot.zfs.useKeyringForCredentials` enabled).
