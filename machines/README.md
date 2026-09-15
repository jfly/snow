# NixOS machines

All machines in this folder are Clan machines. See <https://docs.clan.lol/guides/getting-started/configure/>.

## Defining a new host in the fleet

Just copy the template:

```console
cp -r machines/template/ machines/[HOSTNAME]
```

Edit the resulting files to your taste.

## Bootstrapping a machine over ssh

1. `nix run .#gen-hosts > nixos-modules/shared/host-to-services.toml`
2. Boot the machine into [jflyso](./jflyso/README.md).
3. `clan machines install --update-hardware-config nixos-generate-config --target-host jfly@jflyso [HOSTNAME]`
4. If you're reprovisioning an existing machine, you may want to restore from backups.
   - `sudo systemctl mask restic-backups-snow.service --runtime`: Prevent any
     backups from happening until we've restored.
   - `sudo restic-snow restore latest --target /mnt/restore`: Copy the
     latest backed up data for this host.
   - `sudo systemctl-restore /mnt/restore`: Restore data.
   - Check `/mnt/restore` for anything else you might want to restore.
   - Remove the now empty `/mnt/restore` directory.
   - `sudo systemctl unmask restic-backups-snow.service --runtime`: Re-enable backups.
5. Suggestion: now update your `~/.ssh/config` so you can simply `ssh [HOSTNAME]`.
6. Suggestion: redeploy fflewddur (the ZeroTier controller) to admit the new
   machine to the overlay network.

## Deploying updates

Subsequent updates to the machine:

```console
clan machines update [HOSTNAME]
```
