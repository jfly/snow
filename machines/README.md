# NixOS Machines

All machines in this folder are Clan machines. See <https://docs.clan.lol/guides/getting-started/configure/>.

## Defining a New Host in the Fleet

Just copy the template:

```console
cp -r machines/template/ machines/[HOSTNAME]
```

Edit the resulting files to your taste.

## Bootstrapping a Machine

1. Boot the machine into [jflyso](./jflyso/README.md).
2. `clan machines install --target-host jfly@jflyso [HOSTNAME]`
3. If you're reprovisioning an existing machine, you may want to restore from backups.
   - `sudo restic-snow restore latest --target /tmp/restore`: Copy the
     latest backed up data for this host.
   - `sudo systemctl-restore /tmp/restore/var/lib`: Restore data for systemd services.
   - Finally, check `/tmp/restore` for anything else you might want to restore.
4. Suggestion: now update your `~/.ssh/config` so you can simply `ssh [HOSTNAME]`.

## Deploying Updates

Subsequent updates to the machine:

```console
clan machines update [HOSTNAME]
```
