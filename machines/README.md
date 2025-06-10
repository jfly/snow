# NixOS Machines

All machines in this folder are Clan machines. See <https://docs.clan.lol/guides/getting-started/configure/>.

## Defining a new host in the fleet

This just creates the relevant nix code, it does not try to connect to
anything:

    cp -r machines/template/ machines/[HOSTNAME]

Edit the resulting files to your taste.

## Test host in a VM

    clan vms run [HOSTNAME]

## Bootstrapping a machine

You need SSH access to the machine. One easy way to do that is to boot with the
`jflyso` live USB:

    sudo nix run .#jflyso-netboot

If netboot is not an option, see `./jflyso/README.md` for alternatives.

Next, bootstrap the machine. If you're not
using `jflyso`, change the `--target-host` option accordingly.

    clan machines install --target-host jfly@jflyso [HOSTNAME]

Suggestion: now update your `~/.ssh/config` so you can simply `ssh [HOSTNAME]`.

## Deploying updates

Subsequent updates to the machine:

    clan machines update [HOSTNAME]
