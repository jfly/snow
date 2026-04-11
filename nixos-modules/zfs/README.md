# ZFS

## Initializing a pool

If creating a new pool (you may want to change the permissions of the root
folder after this):

```console
$ zpool create \
    -o ashift=12 \
    -O encryption=on \
    -O keyformat=passphrase \
    -O keylocation=file://[pathtosecret] \
    -O canmount=off \
    -O mountpoint=none \
    -O xattr=sa \
    -O atime=off \
    -O acltype=posixacl \
    -O recordsize=1M \
    -O com.sun:auto-snapshot=true \
    [poolname] \
    /dev/disk/by-id/[FILLME]
```

## Add datasets

For example:

```console
$ sudo zfs create -o mountpoint=legacy [poolname]/[datasetname]
```

## Adding another drive

Connect the new drive. Find it in `/dev/disk/by-id`.

First, sanity check the drive with `smartctl`. Any non-zero values are
concerning.

> [SnapRaid](https://www.snapraid.it/faq#smart):
>
> If any of the SMART attributes `Reallocated_Sector_Ct` (5),
> `Reported_Uncorrect` (187), `Command_Timeout` (188), `Current_Pending_Sector` (197),
> or `Offline_Uncorrectable` (198) are non-zero, replace the disk

Also sanity check `Power_On_Hours` (9), if the device has gotten a ton of usage,
perhaps reconsider using it?

Not all drives report all of these metrics. Apparently some sellers wipe them
before selling drives, so YMMV. Here's a real drive of mine:

```console
$ sudo smartctl --all /dev/disk/by-id/[FILLME]
Vendor Specific SMART Attributes with Thresholds:
ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
  1 Raw_Read_Error_Rate     0x002f   200   200   051    Pre-fail  Always       -       0
  3 Spin_Up_Time            0x0027   200   200   021    Pre-fail  Always       -       2975
  4 Start_Stop_Count        0x0032   100   100   000    Old_age   Always       -       524
  5 Reallocated_Sector_Ct   0x0033   200   200   140    Pre-fail  Always       -       0
  7 Seek_Error_Rate         0x002e   200   200   000    Old_age   Always       -       0
  9 Power_On_Hours          0x0032   062   062   000    Old_age   Always       -       27903
 10 Spin_Retry_Count        0x0032   100   100   000    Old_age   Always       -       0
 11 Calibration_Retry_Count 0x0032   100   253   000    Old_age   Always       -       0
 12 Power_Cycle_Count       0x0032   100   100   000    Old_age   Always       -       98
192 Power-Off_Retract_Count 0x0032   200   200   000    Old_age   Always       -       49
193 Load_Cycle_Count        0x0032   197   197   000    Old_age   Always       -       9632
194 Temperature_Celsius     0x0022   116   104   000    Old_age   Always       -       31
196 Reallocated_Event_Count 0x0032   200   200   000    Old_age   Always       -       0
197 Current_Pending_Sector  0x0032   200   200   000    Old_age   Always       -       0
198 Offline_Uncorrectable   0x0030   100   253   000    Old_age   Offline      -       0
199 UDMA_CRC_Error_Count    0x0032   200   200   000    Old_age   Always       -       1
200 Multi_Zone_Error_Rate   0x0008   100   253   000    Old_age   Offline      -       0
```

Next, speedtest the drive. I only look at the "Timing buffered disk reads"
number. For HDDs, I expect this to be near 200MB/s. I once plugged an external
USB drive into a USB 2.0 jack and was living with ~30MB/s speeds for an
embarrassingly long time.

```console
$ hdparm -Ttv /dev/disk/by-id/[FILLME]
/dev/disk/by-id/[FILLME]:
 multcount     =  0 (off)
 readonly      =  0 (off)
 readahead     = 2048 (on)
 geometry      = 7630885/64/32, sectors = 15628053167, start = 0
 Timing cached reads:   37418 MB in  2.00 seconds = 18739.53 MB/sec
 Timing buffered disk reads: 582 MB in  3.01 seconds = 193.50 MB/sec
```

For now, I'm not running active tests (`smartctl --test=long`). If you have
thoughts on this, please let me know.

Now add that drive to the pool (if the pool doesn't exist yet, see next command):

```
zpool add [poolname] /dev/disk/by-id/[FILLME]
```
