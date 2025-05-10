# `fflam`

Experimental mail server running on Hetzner Cloud.

## Bootstrapping

Following the instructions on
<https://wiki.nixos.org/wiki/Install_NixOS_on_Hetzner_Cloud> and
<https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html#setup-all-other-dns-requirements>.

1. `cd hosts/fflam`
2. Set up a hcloud context: `hcloud context create snow`.
   - This requires creating a Hetzner project and a read/write API token associated with that project.
   - I opted to remove `active_context` from `~/.config/hcloud/cli.toml` in
     favor of setting it explicitly with `HCLOUD_CONTEXT`.
3. Upload my SSH public key to Hetzner:
   ```shell
   hcloud ssh-key create --name 'jfly laptop' --public-key-from-file ~/sync/jfly-linux-secrets/.ssh/id_ed25519.pub
   ```
4. Create a VM:
   ```shell
   hcloud server create --name fflam --type cpx11 --image ubuntu-24.04 --location hil --ssh-key 'jfly laptop'
   ```
5. Check if the IPv4 address you just received is suspicious: <https://check.spamhaus.org/results/?query=5.78.116.143>
6. If the IP is good, enable deletion protection for the IP in Hetzner.
7. Deploy (use the IP from the previous step):
   ```shell
   cd ../..  # back to the root of the repo
   nix run github:nix-community/nixos-anywhere -- --flake .#fflam root@[IP HERE]
   ```
8. Update `iac/pulumi/app/dns.py` accordingly, deploy updates.
9. Manually set up a reverse DNS (rDNS) entry in Hetzner cloud for that IPv4
   address to match the previous step.
10. Verify you can receive email. I used `aerc` for this. Unfortunately,
    sending will have to wait a while.
11. Wait a month and pay your first invoice, then request Hetzner to unblock port 25.
    <https://docs.hetzner.com/cloud/servers/faq/#why-can-i-not-send-any-mails-from-my-server>
11. See how you score on <https://mail-tester.com/>.
