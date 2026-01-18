import pulumi
from typing import Self
from pathlib import Path
import pulumi_cloudflare as cloudflare
from .deage import deage


# See <https://serverfault.com/questions/7478/recommended-dns-ttl> for a discussion of this.
# TL;DR: 5 minutes is a nice balance between short and not crazy short.
DEFAULT_TTL = 300


class SrvValue:
    def __init__(self, priority: int, weight: int, port: int, target: str):
        self.priority = priority
        self.weight = weight
        self.port = port
        self.target = target

    @classmethod
    def no_target(cls) -> Self:
        # > A Target of "." means that the service is decidedly not
        # > available at this domain.
        # From <https://www.ietf.org/rfc/rfc2782.txt>
        return cls(priority=0, weight=0, port=0, target=".")


class Zone:
    def __init__(self, name: str, id: str):
        self._name = name
        self._id = id

    def cname(self, name: str, content: str):
        cloudflare.DnsRecord(
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
            cloudflare.DnsRecord(
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
            cloudflare.DnsRecord(
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
                cloudflare.DnsRecord(
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
        # CloudFlare expects all TXT records to be quoted, with quotation marks
        # escaped accordingly. See
        # <https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/>
        # for details.
        # Furthermore, it appears the quoted strings must be no longer than 255
        # characters, and instead must be a space separated list of quoted strings.
        # This all feels like a leaky abstraction on tope of zonefiles, but it
        # is what it is.
        def chunkify[E](arr: list[E], max_length: int) -> list[list[E]]:
            chunks: list[list[E]] = []
            for el in arr:
                if len(chunks) == 0 or len(chunks[-1]) >= max_length:
                    chunks.append([])

                chunks[-1].append(el)

            return chunks

        def escape_string(s: str) -> str:
            return '"' + s.replace('"', '\\"') + '"'

        chunks = chunkify(list(content), max_length=255)
        content = " ".join(escape_string("".join(chunk)) for chunk in chunks)

        cloudflare.DnsRecord(
            f"txt-{name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="TXT",
            content=content,
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )

    def srv(
        self,
        service: str,
        proto: str,
        value: SrvValue,
    ):
        # This format is explained here:
        # <https://www.cloudflare.com/learning/dns/dns-records/dns-srv-record/>
        name = f"_{service}._{proto}"
        cloudflare.DnsRecord(
            f"srv-{name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="SRV",
            priority=value.priority,
            data=cloudflare.DnsRecordDataArgs(
                priority=value.priority,
                weight=value.weight,
                port=value.port,
                target=value.target,
            ),
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )


class Dns:
    def __init__(self):
        self._jflei_com = Zone(name="jflei.com", id="6c65a9f3de03e7704531813603576415")
        self._jfly_fyi = Zone(name="jfly.fyi", id="ad1bf6d9fca4fee60601e6faa5cc01b6")

        self._github_pages()
        self._san_clemente()
        self._legacy_snowdon()
        self._snow()
        self._google_workspace()
        self._self_hosted_mailserver()
        self._fastmail()

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
        self._jflei_com.cname(secret_project, "3881b6ccac0e9f74.vercel-dns-017.com.")

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

    def _self_hosted_mailserver(self):
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

        # Create `DMARC` record.
        self._jflei_com.txt(
            f"_dmarc.{email_domain}",
            "v=DMARC1; p=reject; adkim=s; aspf=s;",
        )

    def _fastmail(self):
        # https://www.fastmail.help/hc/en-us/articles/360060591153-Manual-DNS-configuration

        # Standard Mail
        self._jfly_fyi.mx(
            "@",
            {
                10: ["in1-smtp.messagingengine.com"],
                20: ["in2-smtp.messagingengine.com"],
            },
        )

        # DKIM
        self._jfly_fyi.cname("fm1._domainkey", "fm1.jfly.fyi.dkim.fmhosted.com")
        self._jfly_fyi.cname("fm2._domainkey", "fm2.jfly.fyi.dkim.fmhosted.com")
        self._jfly_fyi.cname("fm3._domainkey", "fm3.jfly.fyi.dkim.fmhosted.com")

        # SPF
        self._jfly_fyi.txt("@", "v=spf1 include:spf.messagingengine.com ?all")

        # DMARC
        self._jfly_fyi.txt("_dmarc", "v=DMARC1; p=none;")

        # Client email auto-discovery
        self._jfly_fyi.srv("submission", "tcp", value=SrvValue.no_target())
        self._jfly_fyi.srv("imap", "tcp", value=SrvValue.no_target())
        self._jfly_fyi.srv("pop3", "tcp", value=SrvValue.no_target())
        self._jfly_fyi.srv(
            "submissions", "tcp", value=SrvValue(0, 1, 465, "smtp.fastmail.com")
        )
        self._jfly_fyi.srv(
            "imaps", "tcp", value=SrvValue(0, 1, 993, "imap.fastmail.com")
        )
        self._jfly_fyi.srv(
            "pop3s", "tcp", value=SrvValue(10, 1, 995, "pop.fastmail.com")
        )
        self._jfly_fyi.srv("jmap", "tcp", value=SrvValue(0, 1, 443, "api.fastmail.com"))
        self._jfly_fyi.srv(
            "autodiscover",
            "tcp",
            value=SrvValue(0, 1, 443, "autodiscover.fastmail.com"),
        )

        # Client CardDAV auto-discovery
        self._jfly_fyi.srv("carddav", "tcp", value=SrvValue.no_target())
        self._jfly_fyi.srv(
            "carddavs", "tcp", value=SrvValue(0, 1, 443, "carddav.fastmail.com")
        )

        # Client CalDAV auto-discovery
        self._jfly_fyi.srv("caldav", "tcp", value=SrvValue.no_target())
        self._jfly_fyi.srv(
            "caldavs", "tcp", value=SrvValue(0, 1, 443, "caldav.fastmail.com")
        )
