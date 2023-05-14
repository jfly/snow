import pulumi
import pulumi_cloudflare as cloudflare


# See https://serverfault.com/questions/7478/recommended-dns-ttl for a discussion of this.
# tl;dr: 5 minutes is a nice balance between short and not crazy short.
DEFAULT_TTL = 300


class Zone:
    def __init__(self, name: str, id: str):
        self._name = name
        self._id = id

    def cname(self, name: str, value: str):
        cloudflare.Record(
            f"{name}.{self._name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="CNAME",
            value=value,
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )

    def a(self, name: str, values: list[str]):
        for i, value in enumerate(values):
            cloudflare.Record(
                f"{name}-{i+1}",
                name=name,
                ttl=DEFAULT_TTL,
                type="A",
                value=value,
                zone_id=self._id,
                opts=pulumi.ResourceOptions(protect=True),
            )

    def mx(self, name: str, values_by_priority: dict[int, list[str]]):
        for priority, values in values_by_priority.items():
            for i, value in enumerate(values):
                cloudflare.Record(
                    f"mx-{name}-p{priority}-{i+1}",
                    name=name,
                    priority=priority,
                    ttl=DEFAULT_TTL,
                    type="MX",
                    value=value,
                    zone_id=self._id,
                    opts=pulumi.ResourceOptions(protect=True),
                )

    def txt(self, name: str, value: str):
        cloudflare.Record(
            f"txt-{name}",
            name=name,
            ttl=DEFAULT_TTL,
            type="TXT",
            value=value,
            zone_id=self._id,
            opts=pulumi.ResourceOptions(protect=True),
        )


class Dns:
    def __init__(self):
        self._jflei_com = Zone(name="jflei.com", id="6c65a9f3de03e7704531813603576415")

        self._github_pages()
        self._sendgrid()
        self._san_clemente()
        self._snow()
        self._google_workspace()

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

    def _sendgrid(self):
        self._jflei_com.cname("em3602.snowdon", "u33213007.wl008.sendgrid.net")
        self._jflei_com.cname(
            "s1._domainkey.snowdon", "s1.domainkey.u33213007.wl008.sendgrid.net"
        )
        self._jflei_com.cname(
            "s2._domainkey.snowdon", "s2.domainkey.u33213007.wl008.sendgrid.net"
        )

    def _san_clemente(self):
        # sc.jflei.com
        # NOTE: sc.jflei.com is a DDNS entry that should be updated by a
        # Raspberry Pi in San Clemente, but that's currently broken.
        self._jflei_com.cname("*.sc", "sc.jflei.com")

    def _snow(self):
        # snow.jflei.com
        # NOTE: colusa.jflei.com is a DDNS entry that's managed by strider (our
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
