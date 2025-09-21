import pulumi
from pathlib import Path
import pulumi_cloudflare as cloudflare
from .deage import deage


# See https://serverfault.com/questions/7478/recommended-dns-ttl for a discussion of this.
# TL;DR: 5 minutes is a nice balance between short and not crazy short.
DEFAULT_TTL = 300


class Zone:
    def __init__(self, name: str, id: str):
        self._name = name
        self._id = id

    def cname(self, name: str, content: str):
        cloudflare.Record(
            f"{name}.{self._name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="CNAME",
            content=content,
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )

    def a(self, name: str, values: list[str]):
        for i, content in enumerate(values):
            cloudflare.Record(
                f"a-{name}-{i + 1}",
                name=name,
                ttl=DEFAULT_TTL,
                type="A",
                content=content,
                zone_id=self._id,
                opts=pulumi.ResourceOptions(protect=True),
            )

    def aaaa(self, name: str, values: list[str]):
        for i, content in enumerate(values):
            cloudflare.Record(
                f"aaaa-{name}-{i + 1}",
                name=name,
                ttl=DEFAULT_TTL,
                type="AAAA",
                content=content,
                zone_id=self._id,
                opts=pulumi.ResourceOptions(protect=True),
            )

    def mx(self, name: str, values_by_priority: dict[int, list[str]]):
        for priority, values in values_by_priority.items():
            for i, content in enumerate(values):
                cloudflare.Record(
                    f"mx-{name}-p{priority}-{i + 1}",
                    name=name,
                    priority=priority,
                    ttl=DEFAULT_TTL,
                    type="MX",
                    content=content,
                    zone_id=self._id,
                    opts=pulumi.ResourceOptions(protect=True),
                )

    def txt(self, name: str, content: str):
        cloudflare.Record(
            f"txt-{name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="TXT",
            content=content,
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )


class Dns:
    def __init__(self):
        self._jflei_com = Zone(name="jflei.com", id="6c65a9f3de03e7704531813603576415")

        self._github_pages()
        self._san_clemente()
        self._legacy_snowdon()
        self._snow()
        self._google_workspace()
        self._mail()

        self._secret_projects()

    def _secret_projects(self):
        # Hush now
        secret_project = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBNejhBK0hydFplRUtBaEFl
            akloN2puT3BCRU91dlBSaCtBamdzaytxUURvClJ6cjNYUXBNTkM2N1NXUlJZVFJ4
            RXRFSHF0Z25DdzlGMXVnSDVRTXdGSE0KLS0tIHJpbUNXQnlrUXdJd3FRYVRPZ2Jo
            YUdnbzNibWpUbkhUSko4Mk5oYUdUbzQKtrMSCZydHJJL96zTVufVp94xXu2eS2EV
            VNnwBd1UyDweXbQ2s4FW
            -----END AGE ENCRYPTED FILE-----
            """
        )
        self._jflei_com.cname(secret_project, "cname.vercel-dns.com.")

    def _github_pages(self):
        # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain
        self._jflei_com.cname("www", "jfly.github.io")
        # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain
        # Note: CloudFlare does not support ALIAS or ANAME records, so we've gotta list these IPs instead.
        self._jflei_com.a(
            "jflei.com",
            [
                "185.199.108.153",
                "185.199.109.153",
                "185.199.110.153",
                "185.199.111.153",
            ],
        )

    def _san_clemente(self):
        # `sc.jflei.com`
        # NOTE: `sc.jflei.com` is a DDNS entry that should be updated by a
        # Raspberry Pi in San Clemente, but that's currently broken.
        self._jflei_com.cname("*.sc", "sc.jflei.com")

    def _legacy_snowdon(self):
        # `snowdon.jflei.com`
        # NOTE: `colusa.jflei.com` is a DDNS entry that's managed by `strider` (our
        # primary Colusa router).
        self._jflei_com.cname("*.snowdon", "colusa.jflei.com")
        self._jflei_com.cname("snowdon", "colusa.jflei.com")

    def _snow(self):
        # `snow.jflei.com`
        # NOTE: `colusa.jflei.com` is a DDNS entry that's managed by `strider` (our
        # primary Colusa router).
        self._jflei_com.cname("*.snow", "colusa.jflei.com")
        self._jflei_com.cname("snow", "colusa.jflei.com")

    def _google_workspace(self):
        self._jflei_com.mx(
            "jflei.com",
            {
                1: ["aspmx.l.google.com"],
                5: ["alt1.aspmx.l.google.com", "alt2.aspmx.l.google.com"],
                10: ["alt3.aspmx.l.google.com", "alt4.aspmx.l.google.com"],
            },
        )
        self._jflei_com.txt(
            "google._domainkey",
            "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAj8SEHdHgkBVlTXdYyahiOOjzgdOa1H87eO74KsWqkMGP4eJ+9lpJWqBuHz9Ql48JNOZgpve7lDy8UTjW68RCg/0QOccXW07dqHNCJETsvRVWj+Z0qpWcoJbdrf+GJqGUgHdPUZ9JQZU3RoFti7Uuz/anpuzE8P8WjQ5JWIy5xCvliHf7liiy7/fdOMzoclieem8SMZ5Bote7vwOlWZ/H9XRYpuZRRlHvp7KXRDjVTgtpliyQ15GLZTKd/mvHfG78Kz9dnsf1I6EqFe1k8US68b3IoWtTVa+anrIXRFtREbwl/y3XpwX1Z6FtLiPwwdWqiQb91C/uYmF4DA1XU7sVnwIDAQAB",
        )
        self._jflei_com.txt("jflei.com", "v=spf1 include:_spf.google.com ~all")

    def _mail(self):
        # Keep this in sync with `hosts/doli/mail.nix`.
        # Fairly hidden: this is the domain name of the mailserver.
        mx_domain = "mail.playground.jflei.com"
        # Very public. This is the thing after the @ sign in email addresses.
        email_domain = "playground.jflei.com"

        self._jflei_com.a(
            name=mx_domain,
            values=["5.78.116.143"],  # `hosts/doli/network.nix`
        )
        self._jflei_com.aaaa(
            name=mx_domain,
            values=["2a01:4ff:1f0:ad06::"],  # `hosts/doli/network.nix`
        )

        # Create MX record.
        self._jflei_com.mx(
            email_domain,
            {10: [mx_domain]},
        )

        # Create SPF record.
        self._jflei_com.txt(
            email_domain,
            # See <https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/302> for an explanation
            # why we use `~all` rather than `-all`.
            "v=spf1 mx ~all",
        )

        # Create DKIM record (https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html#set-dkim-signature)
        # From `/var/dkim/playground.jflei.com.mail.txt` on `doli`.
        selector = "mail"
        txt_value = (
            Path(
                f"../../vars/per-machine/doli/dkim-{email_domain}.{selector}/txt/value"
            )
            .read_text()
            .strip()
        )
        self._jflei_com.txt(f"{selector}._domainkey.{email_domain}", txt_value)

        # Create `DMARC` record
        self._jflei_com.txt(
            f"_dmarc.{email_domain}",
            "v=DMARC1; p=reject; adkim=s; aspf=s;",
        )
