# snow

Short for snowdon, the street on which I started playing around with Nix.

I manage a mix of things in this repo:

- [A fleet of NixOS machines](#nixos)
- [A handful of routers running OpenWrt](#openwrt)
- [IAC for Kubernetes + misc](#iac)

# NixOS

To get a list of hosts:

    ls hosts

To deploy a machine:

    tools/deploy 'dallben'

# OpenWrt

I manage a few routers with
[astro/nix-openwrt-imagebuilder](https://github.com/astro/nix-openwrt-imagebuilder).

It's miles better than using OpenWrt directly, but still doesn't feel nearly as
awesome as regular NixOS:

- No module system with nicely typed options
- Making changes requires reflashing the device
- Secrets get leaked to `/nix/store`

We could potentially clean some of this up if we were willing to generate UCI
ourselves. See
https://openwrt.org/docs/guide-user/base-system/uci#uci_dataobject_model, and
some prior art here:
https://discourse.nixos.org/t/example-on-how-to-configure-openwrt-with-nixos-modules/18942
However, I think it would be more interesting to explore
https://www.liminix.org/ as an alternative to all of this.

To get a list of routers:

    echo pkgs/*-openwrt

To deploy a given router:

    tools/deploy openwrt/strider

It's still possible to make changes to the router directly. If that happens,
you can pull the latest configuration directly from the live router. For
example:

    openwrt/aragorn/pull.sh

**Note**: this will be a mess to deal with! There will likely be secrets in the
files! There will also be files you don't need. Be careful.

# IAC

Most of the infra-as-code (IAC) in this repo manages resources running on a
Kubernetes cluster ([k3s](https://k3s.io/) running on NixOS).

- Most of the resources on the cluster are managed in a Pulumi app in
  [iac/pulumi](iac/pulumi].) There are also some non-k8s resources managed in
  this Pulumi app as well.
- Some of the oldest k8s resources are managed as flat yaml files in
  [iac/k8s](iac/k8s). I'd like to port this all to Pulumi.

## Kubernetes

I'm fairly happy with Kubernetes: it does a really good job of running a bunch
of containers. It's very flexible, and the active community means that most
things I want to do have already been done by somebody else.

There are some things I don't love:

- Kubernetes makes it really easy to build up circular dependencies that make
  it hard/impossible to recreate your cluster.
  - I manage my cluster with a Pulumi app whose state is stored in a
    [MinIO](https://min.io/) "s3" bucket, but MinIO *itself* is running on
    Kubernetes.
  - I run an [OCI Registry](https://docs.docker.com/registry/) on my Kubernetes
    cluster, which my Kubernetes cluster pulls images from. Astonishingly, this
    works, even with HTTPS (thank you [cert-manager](https://cert-manager.io/)!).
  - The one time I had to recreate
    my cluster was a stressful full morning of effort, and my cluster has only
    gotten more complicated since then. I wonder if I should move these sorts
    of core dependencies out of my Kubernetes cluster. I also wonder if I
    should be regularly recreating my cluster from scratch to make sure I don't
    lose the ability to do so.
- I miss the NixOS module ecosystem. Going back to configuring software with
  plaintext files, or wiring up an application to its database feel like a
  tremendous step backwards (Helm Charts are probably supposed to be "the
  answer" to this, but I've always found them clunky to work with). Moonshot
  project idea: a tool that could convert NixOS modules to Kubernetes resource
  definitions. This wouldn't work for all NixOS modules, but I suspect a lot of
  them are fairly simple (set up a database with a user for this application,
  create a config file for this application, go), and could be converted to
  analogous k8s resources.

**TODO**: My cluster currently is a single node. I intend to beef it up a
collection of 3 servers. This will force me to figure out persistent volumes
and a better story for load balancing:

- [MetalLB](https://metallb.universe.tf/) looks promising for load balancing.
- [Rook/Ceph](https://rook.io/) looks promising for persistent volumes.

# Backups

I use [restic](https://restic.net/). It's great. I'm sure other options are
great too. [This blog post by Filippo
Valsorda](https://words.filippo.io/restic-cryptography/) made me feel
comfortable with choosing it.

I haven't figured out a good story for backing up databases in a
transactionally consistent manner. This isn't really Kubernetes's fault. I've
considered going off the deep end and trying out a filesystem that supports
atomic snapshots (such at [Btrfs](https://en.wikipedia.org/wiki/Btrfs) or
[Open ZFS](https://en.wikipedia.org/wiki/OpenZFS)).

**TODO**: I intend to back up to an offsite, non-cloud location I control, as
well as a cloud provider. For now, I've got a single, out of date offsite
backup, and multiple "hot" copies of the most important data
([Bitwarden](https://bitwarden.com/)/[Vaultwarden](https://github.com/dani-garcia/vaultwarden)
and [Syncthing](https://syncthing.net/)) on my end devices.

# Monitoring

I use [Uptime Kuma](https://github.com/louislam/uptime-kuma). I
picked it because it's simple.

Since I don't trust myself to keep Uptime Kuma up, I monitor *it* with a free
[StatusCake](https://statuscake.com/) account

**TODO**: I don't currently don't monitor various host and Kubernetes metrics
(disk space, cpu, pods flapping, etc). I also don't do much monitoring of
application health (for example, restarting my NFS server often causes issues
for my pods that mount it). I suspect I should bring in other tool to help with
this. Is [Prometheus](https://prometheus.io/) an answer, or is it just a piece
of a full solution?

## Alerting

I've configured Uptime Kuma to email me via [Sendgrid](https://sendgrid.com/).

I've configured StatusCake to notify me via
[Zenduty](https://www.zenduty.com/). This is because I once missed an email
from Zenduty (I never got a "down" alert, just the "up" alert), so I don't
trust them to email me anymore.

**TODO**: Could I get rid of Sendgrid in favor of running my own mail server
with
[nixos-mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver)?
(I'd also like to set up emailing for my [Nextcloud](https://nextcloud.com/)
instance.) Should I eliminate Sendgrid entirely in favor of Zenduty? How should
I handle urgency of alerts?
