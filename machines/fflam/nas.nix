{
  flake,
  ...
}:
{
  imports = [
    flake.nixosModules.zfs
  ];

  clan.core.vars.generators.nas = {
    prompts."password" = {
      persist = true;
      type = "hidden";
    };
  };

  # We don't actually have any ZFS datasets to mount, just a zpool that we push
  # backups to. Ensure the pool is imported!
  boot.zfs.extraPools = [ "baykup" ];
}
