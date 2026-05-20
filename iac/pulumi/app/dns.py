from typing import Self
from pathlib import Path
import pulumi_cloudflare as cloudflare
from .deage import deage


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
        self.name = name
        self.id = id

    def _ttl(self, proxied: bool) -> int:
        if proxied:
            return 1

        # See <https://serverfault.com/questions/7478/recommended-dns-ttl> for a discussion of this.
        # TL;DR: 5 minutes is a nice balance between short and not crazy short.
        return 300

    def cname(self, name: str, content: str):
        cloudflare.DnsRecord(
            f"{name}.{self.name}",
            name=name,
            ttl=self._ttl(proxied=False),
            type="CNAME",
            content=content,
            zone_id=self.id,
        )

    def a(self, name: str, values: list[str], proxied: bool = False):
        for i, content in enumerate(values):
            cloudflare.DnsRecord(
                f"a-{name}.{self.name}-{i + 1}",
                name=name,
                ttl=self._ttl(proxied=proxied),
                type="A",
                proxied=proxied,
                content=content,
                zone_id=self.id,
            )

    def aaaa(self, name: str, values: list[str], proxied: bool = False):
        for i, content in enumerate(values):
            cloudflare.DnsRecord(
                f"aaaa-{name}.{self.name}-{i + 1}",
                name=name,
                ttl=self._ttl(proxied=proxied),
                type="AAAA",
                proxied=proxied,
                content=content,
                zone_id=self.id,
            )

    def mx(self, name: str, values_by_priority: dict[int, list[str]]):
        for priority, values in values_by_priority.items():
            for i, content in enumerate(values):
                cloudflare.DnsRecord(
                    f"mx-{name}.{self.name}-p{priority}-{i + 1}",
                    name=name,
                    priority=priority,
                    ttl=self._ttl(proxied=False),
                    type="MX",
                    content=content,
                    zone_id=self.id,
                )

    def txt(self, name: str, content: str):
        # CloudFlare expects all TXT records to be quoted, with quotation marks
        # escaped accordingly. See
        # <https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/>
        # for details.
        # Furthermore, it appears the quoted strings must be no longer than 255
        # characters, and instead must be a space separated list of quoted strings.
        # This all feels like a leaky abstraction on top of zonefiles, but it
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
            f"txt-{name}.{self.name}",
            name=name,
            ttl=self._ttl(proxied=False),
            type="TXT",
            content=content,
            zone_id=self.id,
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
            f"srv-{name}.{self.name}",
            name=name,
            ttl=self._ttl(proxied=False),
            type="SRV",
            priority=value.priority,
            data=cloudflare.DnsRecordDataArgs(
                priority=value.priority,
                weight=value.weight,
                port=value.port,
                target=value.target,
            ),
            zone_id=self.id,
        )


class Dns:
    def __init__(self):
        self._jflei_com = Zone(name="jflei.com", id="6c65a9f3de03e7704531813603576415")
        self._jfly_fyi = Zone(name="jfly.fyi", id="ad1bf6d9fca4fee60601e6faa5cc01b6")
        self._ramfly_net = Zone(
            name="ramfly.net", id="8870560b0df2e294a2164cb3f18b6237"
        )

        self._github_pages()
        self._legacy_homepage_redirects()
        self._san_clemente()
        self._snow()
        self._self_hosted_mailserver()
        self._fastmail(self._jfly_fyi)
        self._fastmail(self._ramfly_net)
        self._fastmail(self._ramfly_net, subdomain="wi")
        self._fastmail(self._ramfly_net, subdomain="rb")
        self._secret_projects()
        self._photos()

    def _github_pages(self):
        # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain
        self._jfly_fyi.cname("www", "jfly.github.io")
        # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain
        # Note: CloudFlare does not support ALIAS or ANAME records, so we've gotta list these IPs instead.
        self._jfly_fyi.a(
            "@",
            [
                "185.199.108.153",
                "185.199.109.153",
                "185.199.110.153",
                "185.199.111.153",
            ],
        )
        self._jfly_fyi.aaaa(
            "@",
            [
                "2606:50c0:8000::153",
                "2606:50c0:8001::153",
                "2606:50c0:8002::153",
                "2606:50c0:8003::153",
            ],
        )

    def _legacy_homepage_redirects(self):
        cloudflare.Ruleset(
            "jflei.com-redirects",
            kind="zone",
            name="jflei.com-redirects",
            phase="http_request_dynamic_redirect",
            rules=[
                {
                    "action": "redirect",
                    "action_parameters": {
                        "from_value": {
                            "preserve_query_string": True,
                            "status_code": 307,
                            "target_url": {
                                "expression": 'concat("https://www.jfly.fyi", http.request.uri.path)',
                            },
                        },
                    },
                    "description": "redirect jflei.com to www.jfly.fyi",
                    "enabled": True,
                    "expression": '(http.host eq "jflei.com") or (http.host eq "www.jflei.com")',
                    "ref": "jflei.com-redirects",
                }
            ],
            zone_id=self._jflei_com.id,
        )

        # Note that Cloudflare requires you to specify A/AAAA records to use redirects,
        # even if you don't actually have an underlying domain you're "proxying" to.
        # That's where these random IPs come from.
        # https://developers.cloudflare.com/fundamentals/manage-domains/redirect-domain/
        # https://www.jonathanbecerra.dev/blog/redirect-a-non-resolving-domain-using-cloudflare
        for subdomain in ["@", "www"]:
            self._jflei_com.a(subdomain, ["192.0.2.1"], proxied=True)
            self._jflei_com.aaaa(subdomain, ["100::"], proxied=True)

    def _san_clemente(self):
        # `sc.jflei.com`
        # NOTE: `sc.jflei.com` is a DDNS entry that should be updated by a
        # Raspberry Pi in San Clemente, but that's currently broken.
        self._jflei_com.cname("*.sc", "sc.jflei.com")

    def _snow(self):
        # `snow.jflei.com`
        # NOTE: `colusa.jflei.com` is a DDNS entry that's managed by `strider` (our
        # primary Colusa router).
        self._jflei_com.cname("*.snow", "colusa.jflei.com")
        self._jflei_com.cname("snow", "colusa.jflei.com")

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

    def _secret_projects(self):
        # Hush now
        secret_project = deage(
            """
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSAxTFF6RmxvTVgxYWFYc0kv
            dGNOQ2tUYnpMQVcwMkM4cFVvQm9UQnFPZUI4CkZndk1tVGtsTzdsZHAvRVNnL1p6
            emV2SzNuUlltVjcyT3hEUFpxQ2RpRWMKLS0tIHBQYlJtd3dQUlhzbm40Z3Rmd1BM
            RnorQUhYMzRMMkJVNktEb0hpV0ZUNVEK3lOjD5s0BYsBIYToMx2rtqKG54YnX/pw
            DpreKuDaMYptedcDNe1w
            -----END AGE ENCRYPTED FILE-----
            """
        )
        self._ramfly_net.cname(secret_project, "3881b6ccac0e9f74.vercel-dns-017.com")

    def _photos(self):
        self._ramfly_net.cname("photos", "colusa.jflei.com")

    def _fastmail(self, zone: Zone, subdomain: str | None = None):
        # https://www.fastmail.help/hc/en-us/articles/360060591153-Manual-DNS-configuration
        domain = zone.name
        if subdomain is not None:
            domain = f"{subdomain}.{domain}"

        def zone_name(prefix: str) -> str:
            """
            Given a "prefix" (such as "team1"), return a name suitable for use as a dns entry.
            """
            nonlocal subdomain

            parts = []
            if prefix != "@":
                parts.append(prefix)

            if subdomain is not None:
                parts.append(subdomain)

            name = ".".join(parts)
            return "@" if name == "" else name

        # Standard Mail
        zone.mx(
            zone_name("@"),
            {
                10: ["in1-smtp.messagingengine.com"],
                20: ["in2-smtp.messagingengine.com"],
            },
        )

        # DKIM
        zone.cname(zone_name("fm1._domainkey"), f"fm1.{domain}.dkim.fmhosted.com")
        zone.cname(zone_name("fm2._domainkey"), f"fm2.{domain}.dkim.fmhosted.com")
        zone.cname(zone_name("fm3._domainkey"), f"fm3.{domain}.dkim.fmhosted.com")

        # SPF
        zone.txt(zone_name("@"), "v=spf1 include:spf.messagingengine.com ?all")

        # DMARC
        zone.txt(zone_name("_dmarc"), "v=DMARC1; p=none;")

        # Client email auto-discovery
        zone.srv(zone_name("submission"), "tcp", value=SrvValue.no_target())
        zone.srv(zone_name("imap"), "tcp", value=SrvValue.no_target())
        zone.srv(zone_name("pop3"), "tcp", value=SrvValue.no_target())
        zone.srv(
            zone_name("submissions"),
            "tcp",
            value=SrvValue(0, 1, 465, "smtp.fastmail.com"),
        )
        zone.srv(
            zone_name("imaps"), "tcp", value=SrvValue(0, 1, 993, "imap.fastmail.com")
        )
        zone.srv(
            zone_name("pop3s"), "tcp", value=SrvValue(10, 1, 995, "pop.fastmail.com")
        )
        zone.srv(
            zone_name("jmap"), "tcp", value=SrvValue(0, 1, 443, "api.fastmail.com")
        )
        zone.srv(
            zone_name("autodiscover"),
            "tcp",
            value=SrvValue(0, 1, 443, "autodiscover.fastmail.com"),
        )

        # Client CardDAV auto-discovery
        zone.srv(zone_name("carddav"), "tcp", value=SrvValue.no_target())
        zone.srv(
            zone_name("carddavs"),
            "tcp",
            value=SrvValue(0, 1, 443, "carddav.fastmail.com"),
        )

        # Client CalDAV auto-discovery
        zone.srv(zone_name("caldav"), "tcp", value=SrvValue.no_target())
        zone.srv(
            zone_name("caldavs"),
            "tcp",
            value=SrvValue(0, 1, 443, "caldav.fastmail.com"),
        )
