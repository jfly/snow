# locked-vm

A demo of a machine with an encrypted hard drive, remotely unlockable over ssh
accessible via a TOR hidden service.

## To test it out

1. Start a VM with jflyso: `nix run .#vm -- jfly --iso (nix build --no-link --print-out-paths .#jflyso-iso)/iso/*.iso`
2. Deploy to the VM: `clan machines install --target-host root@localhost:5555 locked-vm`
3. Shutdown the VM, start it without the iso: `nix run .#vm -- jfly`
4. The VM will get blocked in initrd. SSH to it to unlock the disk:
   - Get the Tor address of the machine: `clan vars list locked-vm | grep 'tor-hidden-service/hostname'`
   - In one terminal: `nix run nixpkgs#tor`
   - In another terminal: `nix shell nixpkgs#tor nixpkgs#torsocks --command torify ssh -t root@snowj7pkrfos55kzxfiunthud4hmrh7pjcbcj2t4akgw2cqd3gf2ohad.onion systemctl restart systemd-cryptsetup@crypted.service`
