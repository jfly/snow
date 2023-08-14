from pulumi_kubernetes.core.v1 import (
    HostPathVolumeSourceArgs,
    PersistentVolume,
    PersistentVolumeSpecArgs,
)


class SnowState:
    def __init__(self):
        # Just create a few PVs so PVCs can succeed.
        # TODO: switch to something dynamic. Longhorn?
        # don't forget that pulumi depends on minio which depends on pvs. do
        # not to create a circular dependency!
        for i in range(3):
            PersistentVolume(
                f"snow-state-{i}",
                spec=PersistentVolumeSpecArgs(
                    host_path=HostPathVolumeSourceArgs(
                        path=f"/state/pvs/pv{i}",
                    ),
                    access_modes=["ReadWriteOnce"],
                    capacity={"storage": "10Gi"},
                    storage_class_name="manual",
                    # Note: reclaim policy "Recycle" is deprecated in favor of
                    # dynamic provisioning.
                    # See notes above about how we might do that instead.
                    persistent_volume_reclaim_policy="Recycle",
                ),
            )
