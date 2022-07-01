# Upgrade a Working Disk Drive

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)

The document describes steps to replace a working drive that has not failed.  Perhaps you want to replace it with a larger drive.  The goal of these steps is to LEAVE the drive being replaced in the ZFS pool and replace it with a NEW device without degrading the pool.

* This will reduce the chance of data loss as the data redundancy is not lost during the process.  If you simply remove a drive or wait for it to fail and then remove the drive, then you are at risk of data loss since the pool has reduced redundancy.

* This requires you to have the room a connection to add another drive.  If you do not have this, then you have no choice but to remove the existing drive and replace with a new drive.  Follow the [Instructions to Replace Failed Drive](mark_swap_device_as_failed.md) instead.

---

## Marking Swap Device as Failed

If you are not sure if you have swap enabled with your ZFS on Root installation, you can check for the presence of a partition 2. This is the partition used for swap space.  If you have no results, then you do not have physical swap partitions on your ZFS on Root installation.

```shell
$ ls -l /dev/disk/by-id/ | grep "part2"

# nothing found!
```

This would indicate you have swap partitions, and need to make swap partition as failed:

```shell
lrwxrwxrwx 1 root root 10 Jun 12 20:30 scsi-SATA_WDC_WD60EFAX-68S_WD-WX11DC8PAT0U-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Jun 12 20:30 scsi-SATA_WDC_WD60EFRX-68L_WD-WX21DA87C65F-part2 -> ../../sdb2
lrwxrwxrwx 1 root root 10 Jun 12 20:30 scsi-SATA_WDC_WD60EFRX-68L_WD-WX51D88D2L2P-part2 -> ../../sdc2
lrwxrwxrwx 1 root root 10 Jun 12 20:30 scsi-SATA_WDC_WD60EFRX-68L_WD-WX61D88EYL5R-part2 -> ../../sdd2
```

The `mdadm` utility is used to create mirrored or striped swap partitions.  If you will be replacing a drive then you should mark the device as **failed** before removing it from the system.

* Failure to do so will likely result in no swap being available.  
* Marking the device as failed before removal allows the swap device to function even if in a degraded state.

## Detailed Steps

Swap device created by this ZFS on Root will always end with "2" as partition 2 is used for swap on each device.  You just need to figure out the device letters such as `sda`, `sdb`, `sdb`, etc.

```text
# mdadm --manage /dev/md0 --fail /dev/sdb2

Output:  mdadm: set /dev/sdb2 faulty in /dev/md0

# mdadm --detail /dev/md0

Output:
...
   Number   Major   Minor   RaidDevice State
       0       8        2        0      active sync   /dev/sda2
       -       0        0        1      removed

       1       8       18        -      faulty   /dev/sdb2

```

_Example above will mark device `/dev/sdb2` as failed, you need to replace it with the device name you will be replacing. Then you can power off and remove the device from the system and install the replacement device._

---

## Upgrade a Working Device

The [partition_drive_helper.sh](partition_drive_helper_script.md) script can help you go from a blank replacement device to a fully repaired system.  

```text
 $ sudo -i

 # ./partition_drive_helper.sh

  zfs_on_root Partitioning Helper Script
  ---------------------------------------------------------------------------
  The flags set in this script were specific to this installation at the time
  the zfs_on_root script was executed.  This should not be executed on other
  systems.

  DISK_DEVICE set to: /dev/disk/by-id/PUT_YOUR_DEVICE_NAME_HERE

  Try to detect the path name of the new new device:
  partition_drive_helper.sh -d

  To check device exists and has no partitions:
  partition_drive_helper.sh -c

  To WIPE, DELETE, REMOVE, DESTROY, ZAP, ELIMINATE device partitions:
  partition_drive_helper.sh -w

  To CREATE partitions on an empty device:
  partition_drive_helper.sh -p

  To CHECK and UPDATE /etc/fstab entry
  partition_drive_helper.sh -f

  To REPLACE devices in ZFS Pools (replace old partitions with new ones):
  partition_drive_helper.sh -r

  To REPLACE Swap device in MDADM RAID Configuration
  partition_drive_helper.sh -s

```

1. Determine the name of your _new_ device located in `/dev/disk/by-id`:
    You can manually review the devices listed and determine which the one to use. Or see if this script can help you.  Example below shows all the names given to anew SATA device:

    ```text
    # ./partition_drive_helper.sh -d
    Trying to determine name of possible new device....

    scsi-350014ee2bf8fc47d
    scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK
    wwn-0x50014ee2bf8fc47d

    Confirm the above device is correct and then update this script to use it.
    ```

    NOTE: If the new device has existing partitions, the script will not be able to determine it is new, you will see a message such as:

    ```text
    # ./partition_drive_helper.sh -d
    Trying to determine name of possible new device....


    ERROR: Unable to detect or suggest new device.  If new device has
          existing partitions, this script will not suggest it.  You
          will have to determine which device is the correct one to
          use and update this script to use it.
    ```

2. Edit the `partition_drive_helper.sh` script to set your device name:
    Locate this section of the script:

    ```bash
    # ---------------------------------------------------------------------------
    # Define device name to use:
    DISK_DEVICE=/dev/disk/by-id/PUT_YOUR_DEVICE_NAME_HERE
    # ---------------------------------------------------------------------------
    ```

    Edit the script and replace `PUT_YOUR_DEVICE_NAME_HERE` with the name of the device, and save the changes.

    ```bash
    # ---------------------------------------------------------------------------
    # Define device name to use:
    DISK_DEVICE=/dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK
    # ---------------------------------------------------------------------------
    ```

3. Check the device setting and confirm no partitions exist:

    ```text
    # ./partition_drive_helper.sh -c
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.

    No partitions detected.
    ```

    If partitions exist, the partitions must be removed first.  The output would be something like the following:

    ```text
    # ./partition_drive_helper.sh -c
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.

    Partitions detected:

    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part1
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part2
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part3
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part4
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part5

    You must remove partitions from this device to use this script.
    If this was not expected did you specify the wrong device?
    ```

    NOTE: If you attempt to use the script erase your partitions, you will trigger a safety check:

    ```text
    # ./partition_drive_helper.sh -w

    This script will not delete partitions by default.  You will need to
    manually edit this script and uncomment ENABLE_PARTITION_WIPE and set
    its value to TRUE.
    ```

    _You can edit the script as instructed to remove the safety check and it will remove partitions.  Know what you are doing, you are on your own._

4. Create Partitions on the new device:
    This script contains all the flags used to construct your original partitions and will build the device to look identical to the other partitions on the system.

    ```text
    # ./partition_drive_helper.sh -p
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.

    No partitions detected.

    Creating UEFI Boot Partition
    Creating new GPT entries in memory.
    The operation has completed successfully.
    Creating BIOS Boot Partition
    The operation has completed successfully.
    Creating Swap Partition
    The operation has completed successfully.
    Creating Boot Pool Partition
    The operation has completed successfully.
    Creating Root Pool Partition
    The operation has completed successfully.

    Partitions Created, running partprobe...

    Creating EFI filesystems on -part1 partition
    mkfs.fat 4.1 (2017-01-24)

    Completed Successfully
    ```

5. Determine `bpool` device name to replace:
    The Partition Helper Script is designed to replace failed devices missing from the system since that is detectable.  This procedure is replacing a device that has not failed thus will require you to perform manual commands.

    * In this example I want to replace device ending in serial number `atou` which is device `sdd`:

    ```shell
    $ ls -l /dev/disk/by-id/ | grep -i "at0u" | head -1

    lrwxrwxrwx 1 root root  9 Jun 25 14:26 scsi-SATA_WDC_WD60EFAX-68S_WD-WX11DC8PAT0U -> ../../sdd
    ```

    * This shows all the possible names that device `sdd` has which `zpool` may reference for the ZFS `bpool` pool (which is using partition 3):

    ```shell
    $ ls -l /dev/disk/by-id/ | grep -i "sdd" | grep "part3"

    lrwxrwxrwx 1 root root 10 Jun 25 14:26 scsi-350014ee2bb92ce6a-part3 -> ../../sdd3
    lrwxrwxrwx 1 root root 10 Jun 25 14:26 scsi-SATA_WDC_WD60EFAX-68S_WD-WX11DC8PAT0U-part3 -> ../../sdd3
    lrwxrwxrwx 1 root root 10 Jun 25 14:26 wwn-0x50014ee2bb92ce6a-part3 -> ../../sdd3
    ```

    * Starting with ZFS `bpool` status, we will determine which device to replace from the information above:

    ```shell
    $ zpool status bpool

      pool: bpool
    state: ONLINE
      scan: scrub repaired 0B in 0 days 00:00:17 with 0 errors on Sun Jun 12 00:24:18 2022
    config:

            NAME                                                  STATE     READ WRITE CKSUM
            bpool                                                 ONLINE       0     0     0
              raidz1-0                                            ONLINE       0     0     0
                scsi-SATA_WDC_WD60EFRX-68L_WD-WX51D88D2L2P-part3  ONLINE       0     0     0
                wwn-0x50014ee2bb92ce6a-part3                      ONLINE       0     0     0
                wwn-0x50014ee2bb344a2e-part3                      ONLINE       0     0     0
                wwn-0x50014ee2bb517115-part3                      ONLINE       0     0     0
    ```

    * The device `wwn-0x50014ee2bb92ce6a-part3` is the name that matches, this is the device that will be replaced.
    * The device `/dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part3` is the name of the NEW device to replace it.
    * Remember the `bpool` will use partition 3, so each device needs to end in `-part3`.

6. Replace Device in `bpool` with New Disk Device:

    This is the equivalent of attaching the new device, waiting for it to resilver, and then detach the old device.

    ```shell
    $ sudo zpool replace bpool wwn-0x50014ee2bb92ce6a-part3 /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part3

    # No output expected.
    ```

    Monitor the resilver process, wait for it to complete.

    ```shell
    $ zpool status bpool
      pool: bpool
    state: ONLINE
    status: One or more devices is currently being resilvered.  The pool will
            continue to function, possibly in a degraded state.
    action: Wait for the resilver to complete.
      scan: resilver in progress since Sat Jun 25 15:41:42 2022
            1.06G scanned at 98.9M/s, 1004M issued at 91.3M/s, 1.06G total
            238M resilvered, 92.29% done, 0 days 00:00:00 to go
    config:

            NAME                                                  STATE     READ WRITE CKSUM
            bpool                                                 ONLINE       0     0     0
              raidz1-0                                            ONLINE       0     0     0
                scsi-SATA_WDC_WD60EFRX-68L_WD-WX51D88D2L2P-part3  ONLINE       0     0     0
                replacing-1                                       ONLINE       0     0     0
                  wwn-0x50014ee2bb92ce6a-part3                    ONLINE       0     0     0
                  scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part3    ONLINE       0     0     0  (resilvering)
                wwn-0x50014ee2bb344a2e-part3                      ONLINE       0     0     0
                wwn-0x50014ee2bb517115-part3                      ONLINE       0     0     0

    errors: No known data errors
    ```

    Once completed, it will not longer reference the old device:

    ```shell
    $ zpool status bpool
      pool: bpool
    state: ONLINE
      scan: resilvered 266M in 0 days 00:00:13 with 0 errors on Sat Jun 25 15:41:55 2022
    config:

            NAME                                                  STATE     READ WRITE CKSUM
            bpool                                                 ONLINE       0     0     0
              raidz1-0                                            ONLINE       0     0     0
                scsi-SATA_WDC_WD60EFRX-68L_WD-WX51D88D2L2P-part3  ONLINE       0     0     0
                scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part3      ONLINE       0     0     0
                wwn-0x50014ee2bb344a2e-part3                      ONLINE       0     0     0
                wwn-0x50014ee2bb517115-part3                      ONLINE       0     0     0

    errors: No known data errors
    ```

7. Determine `rpool` device name to replace:

    * This shows all the possible names that device `sdd` has which `zpool` may reference for the ZFS `rpool` pool (which is using partition 4):

    ```shell
    $ ls -l /dev/disk/by-id/ | grep -i "sdd" | grep "part4"

    lrwxrwxrwx 1 root root 10 Jun 25 14:26 scsi-350014ee2bb92ce6a-part4 -> ../../sdd4
    lrwxrwxrwx 1 root root 10 Jun 25 14:26 scsi-SATA_WDC_WD60EFAX-68S_WD-WX11DC8PAT0U-part4 -> ../../sdd4
    lrwxrwxrwx 1 root root 10 Jun 25 14:26 wwn-0x50014ee2bb92ce6a-part4 -> ../../sdd4
    ```

    * Starting with ZFS `rpool` status, we will determine which device to replace from the information above:

    ```shell
    $ zpool status rpool

      pool: rpool
    state: ONLINE
      scan: scrub repaired 0B in 0 days 09:25:43 with 0 errors on Sun Jun 12 09:49:46 2022
    config:

            NAME        STATE     READ WRITE CKSUM
            rpool       ONLINE       0     0     0
              mirror-0  ONLINE       0     0     0
                sdc4    ONLINE       0     0     0
                sdd4    ONLINE       0     0     0
              mirror-1  ONLINE       0     0     0
                sde4    ONLINE       0     0     0
                sdf4    ONLINE       0     0     0

    errors: No known data errors
    ```

    * NOTE: Annoying ZFS sometimes changes which naming scheme it uses.  All these were created using `/dev/disk/by-id` path but it seems to have been lost over time.
    * The device `sdd4` is the name that matches, this is the device that will be replaced.
    * The device `/dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part4` is the name of the NEW device to replace it.
    * Remember the `rpool` will use partition 4.

8. Replace Device in `rpool` with New Disk Device:

    This is the equivalent of attaching the new device, waiting for it to resilver, and then detach the old device.

    ```shell
    $ sudo zpool replace rpool sdd4 /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part4

    # No output expected.
    ```

    Monitor the resilver process, wait for it to complete.

    ```shell
    $ zpool status rpool

      pool: rpool
    state: ONLINE
    status: One or more devices is currently being resilvered.  The pool will
            continue to function, possibly in a degraded state.
    action: Wait for the resilver to complete.
      scan: resilver in progress since Sat Jun 25 15:57:54 2022
            6.47T scanned at 17.0G/s, 3.78T issued at 9.93G/s, 6.65T total
            2.38G resilvered, 56.90% done, 0 days 00:04:55 to go
    config:

            NAME                                                STATE     READ WRITE CKSUM
            rpool                                               ONLINE       0     0     0
              mirror-0                                          ONLINE       0     0     0
                sdc4                                            ONLINE       0     0     0
                replacing-1                                     ONLINE       0     0     0
                  sdd4                                          ONLINE       0     0     0
                  scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part4  ONLINE       0     0     0  (resilvering)
              mirror-1                                          ONLINE       0     0     0
                sde4                                            ONLINE       0     0     0
                sdf4                                            ONLINE       0     0     0

    errors: No known data errors
    ```

    NOTE: If you are using larger drives, and all drives in the `vdev` have been upgraded and you expect the `vdev` to now be a larger size.  Be sure that `autoexpand` has been enabled.  This can be set while the resilvering is in progress.

    ```shell
      $ zpool set autoexpand=on rpool

      # No output expected.
    ```

    Once resilvering has completed, it will not longer reference the old device:

    ```shell
    $ zpool status rpool
      pool: rpool
    state: ONLINE
      scan: resilvered 2.79T in 0 days 05:59:54 with 0 errors on Sat Jun 25 21:57:48 2022
    config:

            NAME                                              STATE     READ WRITE CKSUM
            rpool                                             ONLINE       0     0     0
              mirror-0                                        ONLINE       0     0     0
                sdc4                                          ONLINE       0     0     0
                scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part4  ONLINE       0     0     0
              mirror-1                                        ONLINE       0     0     0
                sde4                                          ONLINE       0     0     0
                sdf4                                          ONLINE       0     0     0
    ```

9. Power Down System and Removed the Old Device

    The old device is now detached from the ZFS pools and all pools should be `ONLINE` and healthy.   It is now safe to power down the system and remove the old device.

10. Check status of `/etc/fstab`:
    The new device will have a new UUID which needs to replace the old UUID of the previous device.  The script will show the new UUID and attempt to determine what the old UUID was.

    ```text
    $ sudo -i

    # ./partition_drive_helper.sh -f
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.


    Device /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK
    With UUID: 3608-D8FF is not found in /etc/fstab

    This script will not update your /etc/fstab file automatically.
    You need to update the value manually, or if you want this script
    to attempt the update your /etc/fstab file then uncomment
    ENABLE_FSTAB_FILE_UPDATES and set its value to TRUE.

    This could be the entry to update in /etc/fstab
    UUID=E3F5-D027 /boot/efi2 vfat umask=0022,fmask=0022,dmask=0022 0

    Change above to this: UUID=3608-D8FF and then run this script again.
    ```

    Manually edit `/etc/fstab` or remove the safety check within the script to attempt to have the script make the changes for you.

    _With the script safety check removed, the script will perform the update for you and the output would be something like the following:_

    ```text
    ./partition_drive_helper.sh -f
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.


    Device /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK
    With UUID: 3608-D8FF is not found in /etc/fstab

    Attempting /etc/fstab update of UUID=E3F5-D027 to 3608-D8FF

    Update Completed, running again to validate:

    Device /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK
    With UUID: 3608-D8FF is found in /etc/fstab, no action needed.

    Entry found:
    UUID=3608-D8FF /boot/efi2 vfat umask=0022,fmask=0022,dmask=0022 
    ```

11. Mount the new EUFI Directory

    The new entry added to `etc/fstab` needs to be mounted.

    ```shell
    $ sudo mount -a

    # No output expected.
    ```

12. Repopulate EUFI Boot Directory

    From the example above the `/boot/efi2` directory is for the new device.  Checking the contents of this directory it is now empty:

    ```shell
    $ ls /boot/efi2/

    # No output
    ```

    Use `grub-install` to populate the directory.  This example uses `/boot/efi2` adjust as needed for your device.

    ```shell
    $ sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi2 --bootloader-id=ubuntu --recheck --no-floppy
    
    Installing for x86_64-efi platform.
    Installation finished. No error reported.
    ```

    Now the directory is populated:

    ```shell
    $ ls /boot/efi2/
    EFI
    ```

    NOTE: If you get this error message, then the new entry to the `/etc/fstab` is not mounted correctly:

      ```text
      Installing for x86_64-efi platform.
      grub-install: error: /boot/efi2 doesn't look like an EFI partition.
      ```

13. Replace Swap Device in mdadm raid array:

    ```text
      # ./partition_drive_helper.sh -s
      /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.

      MDADM Device: "/dev/md0" is a valid block device, configured for "raid1" has state "clean, degraded"
      mdadm: added /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK-part2
          Rebuild Status : 0% complete
          Rebuild Status : 23% complete
          Rebuild Status : 47% complete
          Rebuild Status : 71% complete
          Rebuild Status : 95% complete
      Completed.
    ```

    Check the status of MDADM Swap Device:

    ```text
    # ./partition_drive_helper.sh -s
    /dev/disk/by-id/scsi-SATA_WDC_WD80EFZZ-68B_WD-CA1040NK is a valid block device.

    MDADM Device: "/dev/md0" is a valid block device, configured for "raid1" has state "clean"

    Nothing to do.
    Completed.
    ```

    Check Status with mdadm:

    ```text
    mdadm -v --detail /dev/md0
    /dev/md0:
              Version : 1.2
        Creation Time : Sat Aug 15 14:00:46 2020
            Raid Level : raid1
            Array Size : 4189184 (4.00 GiB 4.29 GB)
        Used Dev Size : 4189184 (4.00 GiB 4.29 GB)
          Raid Devices : 2
        Total Devices : 2
          Persistence : Superblock is persistent

          Update Time : Sat Aug 15 19:00:52 2020
                State : clean 
        Active Devices : 2
      Working Devices : 2
        Failed Devices : 0
        Spare Devices : 0

    Consistency Policy : resync

                  Name : testlinux:0  (local to host testlinux)
                  UUID : a1e29ce7:4972f93a:0cd6454c:246fdf33
                Events : 62

        Number   Major   Minor   RaidDevice State
          0       8        2        0      active sync   /dev/sda2
          2       8       18        1      active sync   /dev/sdb2
    ```

    The system should be fully functional now.  All zpools and swap devices functional.

14. Script cleanup.  To be safe, edit the `partition_drive_helper.sh` script again and set the edited variables back to their default settings:

    ```text
    # Define device name to use:
    DISK_DEVICE=/dev/disk/by-id/PUT_YOUR_DEVICE_NAME_HERE

    ENABLE_PARTITION_WIPE=FALSE

    ENABLE_FSTAB_FILE_UPDATES=FALSE
    ```

    Save & Exit.  Now if the script is run again, can not make modifications to any device.

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)
