# Marking Swap Device as Failed

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)

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

## Replacing a Failed Device

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
    You can manually review the devices listed and determine which the one to use. Or see if this script can help you.  Example below shows a new SATA device as named by Virtual Box.

    ```text
    # ./partition_drive_helper.sh -d
    Trying to determine name of possible new device....

    ata-VBOX_HARDDISK_VBd008842e-5645e243

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
    DISK_DEVICE=/dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243
    # ---------------------------------------------------------------------------
    ```

3. Check the device setting and confirm no partitions exist:

    ```bash
    ./partition_drive_helper.sh -c
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    No partitions detected.
    ```

    If partitions exist, the partitions must be removed first.  The output would be something like the following:

    ```text
    # ./partition_drive_helper.sh -c
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    Partitions detected:

    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part1
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part2
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part3
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part4
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part5

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
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

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
    Creating EFI filesystems on -part1 partition
    mkfs.fat 4.1 (2017-01-24)

    Completed Successfully
    ```

5. Check status of `/etc/fstab`:
    The new device will have a new UUID which needs to replace the old UUID of the previous device.  The script will show the new UUID and attempt to determine what the old UUID was.

    ```text
    # ./partition_drive_helper.sh -f 
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    Device /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243
    With UUID: C624-E491 is not found in /etc/fstab

    This script will not update your /etc/fstab file automatically.
    You need to update the value manually, or if you want this script
    to attempt the update your /etc/fstab file then uncomment
    ENABLE_FSTAB_FILE_UPDATES and set its value to TRUE.

    This could be the entry to update in /etc/fstab
    UUID=23FF-226F /boot/efi2 vfat umask=0022,fmask=0022,dmask=0022 0

    Change above to this UUID=C624-E491 and then run this script again.
    ```

    Manually edit `/etc/fstab` or remove the safety check within the script to attempt to have the script make the changes for you.

    _With the script safety check removed, the script will perform the update for you and the output would be something like the following:_

    ```text
    # ./partition_drive_helper.sh -f
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    Device /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243
    With UUID: C624-E491 is not found in /etc/fstab

    Attempting /etc/fstab update of UUID=23FF-226F to C624-E491

    Update Completed, running again to validate:

    Device /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243
    With UUID: C624-E491 is found in /etc/fstab, no action needed.

    Entry found:
    UUID=C624-E491 /boot/efi2 vfat umask=0022,fmask=0022,dmask=0022 0
    ```

6. Replace devices in ZFS Pools:
    The script will parse the output of "zpool status" to determine the old device name and replace it with the new partition devices.  This will automatically trigger a resilvering process.  The script will monitor the output until the resilvering process has completed.

    ```text
    # ./partition_drive_helper.sh -r
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    Pool: "bpool" shows DEGRADED state
    Old Device Placeholder: 16826862562842805836
    Old Device Name: /dev/disk/by-id/ata-VBOX_HARDDISK_VB04106fa7-5e7f1c91-part3
    New Device Name: /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part3

    Rebuild of "bpool" Started:
    action: Wait for the resilver to complete. 11.8M resilvered, 5.85% done, 0 days 00:00:16 to go

      scan: resilvered 330M in 0 days 00:00:00 with 0 errors on Sat Aug 15 16:42:45 2020
    DONE: bpool


    Pool: "rpool" shows DEGRADED state
    Old Device Placeholder: 7559734512386936318
    Old Device Name: /dev/disk/by-id/ata-VBOX_HARDDISK_VB04106fa7-5e7f1c91-part4
    New Device Name: /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part4

    Rebuild of "rpool" Started:
    action: Wait for the resilver to complete. 2.68M resilvered, 0.10% done, no estimated completion time

      scan: resilvered 10.5G in 0 days 00:00:24 with 0 errors on Sat Aug 15 16:44:09 2020
    DONE: rpool
    Completed
    ```

7. Replace Swap Device in mdadm raid array:

  ```text
    # ./partition_drive_helper.sh -s
    /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

    MDADM Device: "/dev/md0" is a valid block device, configured for "raid1" has state "clean, degraded"
    mdadm: added /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243-part2
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
  /dev/disk/by-id/ata-VBOX_HARDDISK_VBd008842e-5645e243 is a valid block device.

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

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)
