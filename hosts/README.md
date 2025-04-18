# NixOS Hosts

Each folder in `hosts/` is a different NixOS host.

## Defining a new host in the fleet

This just creates the relevant nix code, it does not try to connect to
anything:

    tools/fleet.py declare [HOSTNAME]

Notably, this configuration will be incomplete: it won't have a
`hardware-configuration.nix` yet. That will be generated when you bootstrap a
physical machine.

## Test host in a VM

    tools/fleet.py vm [HOSTNAME]

## Bootstrapping a machine

You need SSH access to the machine. One easy way to do that is to boot with the
`jflyso` live USB (see `./jflyso/README.md` for instructions). If you're not
using `jflyso`, change the `--ssh` option accordingly.

    tools/fleet.py bootstrap --ssh jfly@jflyso [HOSTNAME]

Now update your ssh_config so you can simply `ssh [HOSTNAME]`.

## Deploying updates

Subsequent updates to the machine:

    tools/deploy [HOSTNAME]
