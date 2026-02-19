# snow

Short for snowdon, the street on which I started playing around with Nix.

I manage a mix of things in this repo:

- [A fleet of NixOS machines](#nixos)
- [A handful of routers running OpenWrt](#openwrt)
- [DNS](#dns)
- [My Kobo](packages/my-kobo/README.md)

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
<https://openwrt.org/docs/guide-user/base-system/uci#uci_dataobject_model>, and
some prior art here:
<https://discourse.nixos.org/t/example-on-how-to-configure-openwrt-with-nixos-modules/18942>
However, I think it would be more interesting to explore
<https://www.liminix.org> as an alternative to all of this.

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

# DNS

My DNS does not spark joy. There are a bunch of places where this happens:

1. We have "private" DNS managed in 2 ways:
   - Static `/etc/hosts` entries for every NixOS machine in the overlay network.
     Look for `networking.extraHosts` in
     [nixos-modules/shared/services.nix](nixos-modules/shared/services.nix).
   - A dnsmasq server for all the non-NixOS machines in the overlay network (we
     can't update their `/etc/hosts`). See
     [machines/fflewddur/zerotier/dns.nix](machines/fflewddur/zerotier/dns.nix).
     Also note the crazy hacks required to get various devices to play nicely
     with an IPv6 only overlay network even when connected to an IPv4 only
     physical network.
3. Public DNS is on CloudFlare, managed by [iac/pulumi](iac/pulumi). This is
   overkill: Pulumi has state, which is annoying to deal with. I'd like to
   explore alternatives to this, perhaps
   [DNSControl](https://docs.dnscontrol.org/) or running our own [hidden primary
   name server](https://dn.org/hidden-primary-name-servers-why-and-how/).
4. There's some "split horizon" DNS managed by OpenWRT. I'd like to port our
   primary router to NixOS someday, and then this can be managed with nix.

## Kubernetes

I ran Kubernetes for many years. It was a great way to learn Kubernetes, and it
does a really good job of running a bunch of containers. It's very flexible,
and the active community means that most things I want to do have already been
done by somebody else.

I eventually moved off of Kubernetes in favor of "bare mental" NixOS. Some of
my reasons:

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
- I missed the NixOS module ecosystem. Going back to configuring software with
  plaintext files, or wiring up an application to its database feel like a
  tremendous step backwards (Helm Charts are supposed to be "the
  answer" to this, but I've always found them clunky to work with).
- Locking/upgrading containers requires additional tooling. Don't get me
  started about patching software.
- I despise the "yaml ops" that is prevelant throughout the k8s ecosystem. I
  managed the state of my cluster with Pulumi, which was a much better
  experience, but you're in the minority if you do that.

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

Backups regularly go to a Hetzner storage box. I also run a backup NAS that I'd
like to move to a friend's house someday.

# Monitoring + Alerting

I use Prometheus for data gathering ("scraping"), Grafana for
exploring/visualizations/dashboards, and Prometheus Alertmanager for alerts.

I have Alertmanger email me through [my self-hosted mailserver](machines/doli/README.md).

I use [ntfy-alertmanager](https://git.xenrox.net/~xenrox/ntfy-alertmanager) to
forward alerts from Alertmanager to my [ntfy](https://ntfy.sh) topic. ntfy is great!

In case my monitoring server dies, I'll find out about it because I have a
deadman switch set up with the excellent <https://healthchecks.io>. This
approach was inspired by <https://jakubstransky.com/2019/01/26/who-monitors-prometheus/>.

I also have an account with [uptimeobserver.com](https://uptimeobserver.com/)
configured to ping my ntfy account [instructions here](https://support.uptimeobserver.com/integrations/ntfy/).
