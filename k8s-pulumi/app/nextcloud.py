from pathlib import Path
import pulumi_keycloak as keycloak
from textwrap import dedent
from pulumi_kubernetes.helm.v3 import Chart, ChartOpts, FetchOpts
from .snowauth import Access, Snowauth
from .deage import deage
from .util import Database, format_traefik_middlewares
from .util import declare_psql


class Nextcloud:
    def __init__(self, snowauth: Snowauth):
        self._snowauth = snowauth

        self._declare_keycloak_client()
        db = self._declare_db()
        self._declare_helm_chart(db)

    def _declare_keycloak_client(self):
        snow_realm = self._snowauth.snow_realm

        # Creating a keycloak client per the instructions here:
        # https://janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/#setup-client-in-keycloak
        client = keycloak.openid.Client(
            "nextcloud",
            realm_id=snow_realm.id,
            client_id="nextcloud",
            name="nextcloud",
            enabled=True,
            access_type="CONFIDENTIAL",
            standard_flow_enabled=True,
            root_url="https://nextcloud.snow.jflei.com",
            valid_redirect_uris=[
                "https://nextcloud.snow.jflei.com/apps/sociallogin/custom_oidc/keycloak",
            ],
            full_scope_allowed=False,
        )
        keycloak.Role(
            "admin-role",
            realm_id=snow_realm.id,
            client_id=client.id,
            description="Admin role",
            name="admin",
        )
        keycloak.Role(
            "colusa-role",
            realm_id=snow_realm.id,
            client_id=client.id,
            description="Residents of 612 Colusa",
            name="colusa",
        )

        keycloak.openid.UserClientRoleProtocolMapper(
            "nextcloud-role-mapper",
            realm_id=snow_realm.id,
            client_id=client.id,
            claim_name="roles",
            add_to_userinfo=True,
            multivalued=True,
            add_to_id_token=False,
        )

        keycloak.openid.UserPropertyProtocolMapper(
            "username-mapper",
            realm_id=snow_realm.id,
            client_id=client.id,
            name="sub",
            user_property="username",
            claim_name="sub",
        )

        """
        ### Configure nextcloud to use openid login ###

        1. Open the App dashboard: https://nextcloud.snow.jflei.com/settings/apps
        2. Install the "Social Login" (search icon at top right)
        3. Navigate to https://nextcloud.snow.jflei.com/settings/admin/sociallogin
        4. Check these options:
            - "Prevent creating an account if the email address exists in another account"
            - "Update user profile on every login"
            - "Restrict login for users without mapped groups"
        5. Save the settings
        6. Click on the Custom OpenID Connect plus button
        7. Enter this information (from https://keycloak.snow.jflei.com/realms/snow/.well-known/openid-configuration)
            - Internal name: keycloak
            - Title: snow
            - Authorize url: https://keycloak.snow.jflei.com/realms/snow/protocol/openid-connect/auth
            - Token url: https://keycloak.snow.jflei.com/realms/snow/protocol/openid-connect/token
            - User info URL (optional): https://keycloak.snow.jflei.com/realms/snow/protocol/openid-connect/userinfo
            - Logout URL (optional): I prefer to leave this unset. This means that logging out will only log the user out of nextcloud rather than keycloak.
                - If you do want to log them out of keycloak, you need to do something like: https://keycloak.snow.jflei.com/realms/snow/protocol/openid-connect/logout?client_id=nextcloud&post_logout_redirect_uri=https%3A%2F%2Fnextcloud.snow.jflei.com
                - NOTE: logout doesn't quite work seamlessly because we're not able to
                  set id_token_hint. For more information:
                    - https://github.com/zorn-v/nextcloud-social-login/issues/391
                    - https://github.com/keycloak/keycloak/discussions/12183
            - Client Id: nextcloud
            - Client Secret: go to https://keycloak.snow.jflei.com/admin/master/console/#/snow/clients, open "nextcloud", click "Credential", copy "Client secret"
            - Scope: openid
            - Groups claim (optional): roles
            - Button style: Keycloak
            - Default group: None
            - Add a mapper with "Add group mapping". Map "admin" to "admin" and "colusa" to "colusa".
                - If you choose to let Nextcloud create the required
                  groups from the userinfo, it would prefix all group names
                  with "keycloak-". We want to avoid this and therefore have to
                  map every single group in Nextcloud.
            - Scroll to the bottom, click "Save"

         8. In [keycloak](https://keycloak.snow.jflei.com/admin/master/console/): assign the relevant nextcloud roles to anyone you wish!
        """

    def _declare_db(self) -> Database:
        return declare_psql(
            version="15.4",
            name="nextclouddb",
            namespace="default",
            schema="nextcloud",
            admin_username="admin",
            admin_password=deage(
                """
                    -----BEGIN AGE ENCRYPTED FILE-----
                    YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBRZ0RuL2FrbTQ3bXR4Yndw
                    OUhFaUNSbWdyOXl3Z3cxczc3NUZhbm9KYW5nCmVYL0xpcnhSdFZqWWZKMkJWbmpt
                    NDg5UW5BZlpmSWU5VGRjRFdPaS9MNWMKLS0tIEE0OXlxSVhPNFR2NUJ0Z25pRWhx
                    ZFB1ay9mWCtmUzE5ZzN2ZURTWmFlOGsKiqWamnJG1hrEQbfweBxrXilv4lnLiq2K
                    1vvsVnQFpTPXfXM0zQreBVs6JExlIptqKkxRqA==
                    -----END AGE ENCRYPTED FILE-----
                """
            ),
        )

    def _declare_helm_chart(self, db: Database):
        # Note: it's ok to expose nextcloud to the world as it has its own
        # login system.
        access = self._snowauth.middlewares_for_access(Access.INTERNET_UNSECURED)

        middlewares = format_traefik_middlewares(
            [*access, self._snowauth._strict_https_middleware]
        )
        Chart(
            "nextcloud",
            ChartOpts(
                chart="nextcloud",
                version="3.5.22",
                fetch_opts=FetchOpts(repo="https://nextcloud.github.io/helm/"),
                values={
                    "nextcloud": {
                        "host": "nextcloud.snow.jflei.com",
                        "username": "admin",
                        "password": deage(
                            """\
                            -----BEGIN AGE ENCRYPTED FILE-----
                            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBmVytmTEc2a0lVamRydkRl
                            QmQ5b2R5Z2F0eGtSaUxmQW45L2k0ZUQ3aWtVCkFUdzhJSGJ3V2Z3ZmptbmZnVmpu
                            WjdNOGMvdmlQMDFxS2w3YmI2NGRsR3cKLS0tIG5GWVZYbG56dlR2VWZGUGNQWVhM
                            dXBkQlFOeFdhWEpaNHZuVllIS1ArRE0KUv8c2mRG8ISmH2aEP4F6/CMJtuNNeu7s
                            bb52cUtHNYlg9kbPBXncriMUOR6d68hDFYE2cg==
                            -----END AGE ENCRYPTED FILE-----
                        """
                        ),
                        "configs": {
                            "custom.config.php": dedent(
                                """\
                                <?php
                                $CONFIG = array (
                                  // Traefik is the entrypoint into our cluster. Trust its
                                  // X-Forwarded-* headers.
                                  'trusted_proxies' => array(
                                    0 => '127.0.0.1',
                                    1 => '10.0.0.0/8',
                                  ),
                                  'forwarded_for_headers' => array('HTTP_X_FORWARDED_FOR'),
                                  // https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#default-phone-region
                                  'default_phone_region' => 'US',
                                );
                                """
                            ),
                        },
                    },
                    "ingress": {
                        "enabled": True,
                        "tls": [
                            {
                                "hosts": ["nextcloud.snow.jflei.com"],
                                "secretName": "nextcloud-tls",
                            },
                        ],
                        # Note: this is copied from `http_ingress`, could we DRY this up?
                        "annotations": {
                            "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                            "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                            "traefik.ingress.kubernetes.io/router.middlewares": middlewares,
                        },
                    },
                    "phpClientHttpsFix": {
                        "enabled": True,
                    },
                    "persistence": {
                        "enabled": True,
                        "storageClass": "manual",
                        "nextcloudData": {
                            "enabled": True,
                            "storageClass": "manual",
                        },
                    },
                    "internalDatabase": {
                        "enabled": False,
                    },
                    "externalDatabase": {
                        "enabled": True,
                        "type": "postgresql",
                        "host": db.hostname(),
                        "database": db.schema,
                        "user": db.admin_username,
                        "password": db.admin_password,
                    },
                    "cronjob": {
                        "enabled": True,
                    },
                    # Switch from apache to nginx: https://github.com/nextcloud/helm/tree/main/charts/nextcloud#using-nginx
                    # For some reason, the default (apache) isn't set up to
                    # support the `/.well-known` endpoints (documented here:
                    # https://docs.nextcloud.com/server/latest/admin_manual/issues/general_troubleshooting.html#service-discovery-label).
                    # The nginx/fpm) flavor *does* have support for these
                    # .well-known endpoints, but the default configuration
                    # doesn't handle being behind a https-terminating proxy
                    # well: they redirect using http, which breaks the ajax
                    # checks the frontend does.
                    # TODO: file an issue upstream asking about all this and
                    # seeing if they'd be open to a PR improving things.
                    "nginx": {
                        "enabled": True,
                        "config": {
                            "default": False,
                            "custom": (
                                Path(__file__).parent / "nextcloud.nginx.conf"
                            ).read_text(),
                        },
                    },
                    "image": {
                        "flavor": "fpm",
                    },
                    "redis": {
                        "enabled": True,
                        "auth": {
                            "password": deage(
                                """
                                -----BEGIN AGE ENCRYPTED FILE-----
                                YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA5eTZDdFRFcDA4cXdXQko0
                                ajY1dVBmdWhiVmw5OGxuT0pLSjBuV0pXSDF3CitRMUU5Q2ViVlFORHlWT0NsVTMr
                                VE5JY29iLzRlKzB0R3NOWjBsZXUyZmMKLS0tIGFPTDFaNnJCK0hWalptZG0xaG41
                                U01zbXZnWmxETTdNb3ozbGF4QVRpUjAKG4TCECMwFRybbA/XKURz8vW9P6hAAfM+
                                S+L4cbZK2ugD7DP5HxqFBS22GFxzb20ZUkanzw==
                                -----END AGE ENCRYPTED FILE-----
                                """
                            ),
                        },
                    },
                    "metrics": {
                        "token": deage(
                            """
                            -----BEGIN AGE ENCRYPTED FILE-----
                            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSA4U05MQmJHb2NIT3h0UzA3
                            a0IzdklGTklBZ2lpU2YyQlJzUzZTVFA1SGhVCkh5dlRiai83ejM5NklwQ1FkbTRH
                            QlgrejBXNURVc2x4L3lkZ2hSLzBkdmcKLS0tIDlyNHZaZjUyWUdpa2hUZ1IvbS9y
                            ZGo4Yjh6K21IdFdySmF5aE9wVjNxTjAKzgquEZJQt1Th/8s/qS87LH4uWwOsnMrL
                            aK25r8bAllYn2WewCLYQ9pqL
                            -----END AGE ENCRYPTED FILE-----
                            """
                        )
                    },
                },
            ),
        )
