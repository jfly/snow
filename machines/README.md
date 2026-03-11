# NixOS Machines

All machines in this folder are Clan machines. See <https://docs.clan.lol/guides/getting-started/configure/>.

## Defining a new host in the fleet

Just copy the template:

```console
cp -r machines/template/ machines/[HOSTNAME]
```

Edit the resulting files to your taste.

## Bootstrapping a machine

1. Boot the machine into [jflyso](./jflyso/README.md).
2. `clan machines install --target-host jfly@jflyso [HOSTNAME]`
3. If you're reprovisioning an existing machine, you may want to restore from backups.
   - `sudo restic-snow restore latest --target /tmp/restore`: To restore the
     latest backed up data for this host. Look through this and manually move any
     directories you want to keep.
4. Suggestion: now update your `~/.ssh/config` so you can simply `ssh [HOSTNAME]`.

## Deploying updates

Subsequent updates to the machine:

    clan machines update [HOSTNAME]
