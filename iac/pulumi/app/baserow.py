import json
import pulumi_minio as minio
from pulumi_kubernetes.helm.v3 import Chart, ChartOpts, FetchOpts
from .snowauth import Snowauth


class Baserow:
    def __init__(self, namespace: str):
        self.namespace = namespace

        user = minio.IamUser("baserow")
        bucket = minio.S3Bucket("baserow", acl="private", bucket="baserow")
        readwrite_policy = minio.IamPolicy(
            "baserow-readwrite",
            policy=bucket.arn.apply(
                lambda bucket_arn: json.dumps(
                    {
                        "Version": "2012-10-17",
                        "Statement": [
                            {
                                "Sid": "ListAllBucket",
                                "Effect": "Allow",
                                "Action": ["s3:*"],
                                "Principal": "*",
                                "Resource": bucket_arn,
                            }
                        ],
                    }
                )
            ),
        )
        minio.IamUserPolicyAttachment(
            "developerIamUserPolicyAttachment",
            user_name=user.id,
            policy_name=readwrite_policy.id,
        )

        # TODO reconfigure psql (and redis?) to persist state somewhere we actually backup
        # TODO secrets are getting recreated on each deploy, figure out a better alternative
        Chart(
            "baserow",
            ChartOpts(
                chart="baserow",
                version="1.24.0",
                fetch_opts=FetchOpts(
                    repo="https://christianknell.github.io/helm-charts",
                ),
                values={
                    "backend": {
                        "ingress": {
                            "enabled": True,
                            "hostname": "api.baserow.snow.jflei.com",
                            "tls": [
                                {
                                    "hosts": ["api.baserow.snow.jflei.com"],
                                    "secretName": "baserow-api-tls",
                                },
                            ],
                            # Note: this is copied from `http_ingress`, could we DRY this up?
                            "annotations": {
                                "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                                "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                            },
                        },
                        "config": {
                            "aws": {
                                "s3EndpointUrl": "minio.snow.jflei.com",
                                "s3CustomDomain": "minio.snow.jflei.com",
                                "accessKeyId": user.name,
                                "secretAccessKey": user.secret,
                                "bucketName": bucket.bucket,
                            },
                        },
                    },
                    "frontend": {
                        "ingress": {
                            "enabled": True,
                            "hostname": "baserow.snow.jflei.com",
                            "tls": [
                                {
                                    "hosts": ["baserow.snow.jflei.com"],
                                    "secretName": "baserow-tls",
                                },
                            ],
                            # Note: this is copied from `http_ingress`, could we DRY this up?
                            "annotations": {
                                "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                                "traefik.ingress.kubernetes.io/router.entrypoints": "websecure",
                            },
                        },
                    },
                    "config": {
                        "publicFrontendUrl": "https://baserow.snow.jflei.com",
                        "publicBackendUrl": "https://api.baserow.snow.jflei.com",
                    },
                },
            ),
        )
