# Convert a Single ZFS Device to ZFS Mirror

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)

This example adds a single device to the system to make a single device ZFS on Root into a mirrored ZFS on Root.  This is non-destructive and can be done on a live working system.  As with any significant system change, you should make a backup first.

NOTE: This example does not use a swap partition.

The [partition_drive_helper.sh](partition_drive_helper_script.md) script can help you convert a single disk ZFS on Root install to a mirrored ZFS on Root.

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
    You can manually review the devices listed and determine which the one to use. Or see if this script can help you.  Example below shows a new Samsung NVMe device with two possible names:

    ```text
    $ sudo -i 

    # ./partition_drive_helper.sh -d

    Trying to determine name of possible new device....

    nvme-eui.002538d2214243a1
    nvme-Samsung_SSD_980_1TB_S64ANS0T201060J

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
    DISK_DEVICE=/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J
    # ---------------------------------------------------------------------------
    ```

3. Check the device setting and confirm no partitions exist:

    ```bash
    ./partition_drive_helper.sh -c

    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J is a valid block device.

    No partitions detected.
    ```

    If partitions exist, the partitions must be removed first.  The output would be something like the following:

    ```text
    # ./partition_drive_helper.sh -c

    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J is a valid block device.

    Partitions detected:

    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part1
    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part3
    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part4
    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part5


    Unable to create partitions, do you need to wipe partitions first?

    ERROR: Create Partitions Failed
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
    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J is a valid block device.

    No partitions detected.

    Creating UEFI Boot Partition
    Creating new GPT entries in memory.
    The operation has completed successfully.
    Creating BIOS Boot Partition
    The operation has completed successfully.
    Creating Boot Pool Partition
    The operation has completed successfully.
    Creating Root Pool Partition
    The operation has completed successfully.
    Creating EFI filesystems on -part1 partition
    mkfs.fat 4.1 (2017-01-24)

    Completed Successfully
    ```

5. Add EFI Partition to `/etc/fstab` file.
    The new device's EFI partition needs to be added to the `/etc/fstab` file.  This will allow the new device to be bootable in the event the primary device fails or is removed.  You will be able to boot from this device instead.

    * The script will not add this directly for you but will give you the information you need to manually add it:

    ```text
    # ./partition_drive_helper.sh -f

    /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J is a valid block device.

    Device /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J
    With UUID: BCD4-2F02 is not found in /etc/fstab

    Unable to determine the device to update in /etc/fstab

    ERROR: Unexpected error detected
    ```

    * You just need the UUID number shown above.

    Next you need to create a directory to mount the partition into.

    ```text
    # ls /boot | grep efi
    efi
    ```

    Based on the example above create an `efi2` directory:

    ```text
    # mkdir /boot/efi2
    ```

    Now add the following line to the `/etc/fstab` file. This has the UUID number from above and the directory you just created.

    ```text
    /dev/disk/by-uuid/BCD4-2F02 /boot/efi2 vfat defaults 0 0
    ```

    * Save and exit your text editor.

6. Mount EFI Partition.  This will read and verify the change you just made to `/etc/fstab` file:

    ```text
    # mount /boot/efi2

    - No output expected.
    ```

    * No output is expected.  If you get an error message then address the issue.

7. Install Grub on EFI Partition
    Now that the new device's EFI partition is mounted, it needs to have grub installed:

    ```text
    # grub-install --target=x86_64-efi --efi-directory=/boot/efi2 --bootloader-id=ubuntu --recheck --no-floppy

    Installing for x86_64-efi platform.
    Installation finished. No error reported.
    ```

    Confirm the new directory has also been populated:

    ```text
    #  ls /boot/e*
    /boot/efi:
    EFI

    /boot/efi2:
    EFI
    ```

---

## Attach ZFS Partitions

Partitions are now created on the new device. The next step is to attach the new partitions to the existing partitions.  As a reminder, with the `ZFS on Root` method, partition #3 is used for the `bpool` boot partitions and partition #4 is used for the `rpool` root partition.

Status before attaching new partitions:

```text
$ zpool status

  pool: bpool
 state: ONLINE
  scan: scrub repaired 0B in 0 days 00:00:02 with 0 errors on Sun May  8 00:24:03 2022
config:

        NAME                                              STATE     READ WRITE CKSUM
        bpool                                             ONLINE       0     0     0
          ata-TEAM_TM8PS7256G_TPBF2201180010700118-part3  ONLINE       0     0     0

errors: No known data errors

  pool: rpool
 state: ONLINE
  scan: scrub repaired 0B in 0 days 00:00:42 with 0 errors on Sun May  8 00:24:43 2022
config:

        NAME                                              STATE     READ WRITE CKSUM
        rpool                                             ONLINE       0     0     0
          ata-TEAM_TM8PS7256G_TPBF2201180010700118-part4  ONLINE       0     0     0

errors: No known data errors
```

The syntax of the ZFS Commands will be:

```shell
# Create boot pool mirror
$ sudo zpool attach -f bpool <existing-device-name>-part3 /dev/disk/by-id/<new-device-name>-part3

# Create root pool mirror
$ sudo zpool attach -f rpool <existing-device-name>-part4 /dev/disk/by-id/<new-device-name>-part4
```

Based on the examples above, the values for:

* `<existing-device-name>` is `ata-TEAM_TM8PS7256G_TPBF2201180010700118`
* `<new-device-name>` is `nvme-Samsung_SSD_980_1TB_S64ANS0T201060J`

### Create the Mirrors

These example are specific to this example, adjust to match your system.

```shell
$ sudo zpool attach -f bpool ata-TEAM_TM8PS7256G_TPBF2201180010700118-part3 /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part3
# No output expected

$ sudo zpool attach -f rpool ata-TEAM_TM8PS7256G_TPBF2201180010700118-part4 /dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part4
# No output expected
```

Now when you check the status, the mirrors will be created, and mirrors will resilver:

```text
$ zpool status
  pool: bpool
 state: ONLINE
  scan: resilvered 536M in 0 days 00:00:02 with 0 errors on Sat May 21 11:32:56 2022
config:

        NAME                                                STATE     READ WRITE CKSUM
        bpool                                               ONLINE       0     0     0
          mirror-0                                          ONLINE       0     0     0
            ata-TEAM_TM8PS7256G_TPBF2201180010700118-part3  ONLINE       0     0     0
            nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part3  ONLINE       0     0     0

errors: No known data errors

  pool: rpool
 state: ONLINE
status: One or more devices is currently being resilvered.  The pool will
        continue to function, possibly in a degraded state.
action: Wait for the resilver to complete.
  scan: resilver in progress since Sat May 21 11:39:41 2022
        16.7G scanned at 488M/s, 7.42G issued at 217M/s, 16.7G total
        8.43G resilvered, 44.44% done, 0 days 00:00:43 to go
config:

        NAME                                                STATE     READ WRITE CKSUM
        rpool                                               ONLINE       0     0     0
          mirror-0                                          ONLINE       0     0     0
            ata-TEAM_TM8PS7256G_TPBF2201180010700118-part4  ONLINE       0     0     0
            nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part4  ONLINE       0     0     0  (resilvering)

```

* Resilvering is expected, this is the process of building the mirror.  Wait for it to complete.

### Completed Mirrors

The `bpool` and `rpool` mirrors have been created and resilvered:

```text
$ zpool status
  pool: bpool
 state: ONLINE
  scan: resilvered 536M in 0 days 00:00:02 with 0 errors on Sat May 21 11:32:56 2022
config:

        NAME                                                STATE     READ WRITE CKSUM
        bpool                                               ONLINE       0     0     0
          mirror-0                                          ONLINE       0     0     0
            ata-TEAM_TM8PS7256G_TPBF2201180010700118-part3  ONLINE       0     0     0
            nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part3  ONLINE       0     0     0

errors: No known data errors

  pool: rpool
 state: ONLINE
  scan: resilvered 18.8G in 0 days 00:01:05 with 0 errors on Sat May 21 11:40:46 2022
config:

        NAME                                                STATE     READ WRITE CKSUM
        rpool                                               ONLINE       0     0     0
          mirror-0                                          ONLINE       0     0     0
            ata-TEAM_TM8PS7256G_TPBF2201180010700118-part4  ONLINE       0     0     0
            nvme-Samsung_SSD_980_1TB_S64ANS0T201060J-part4  ONLINE       0     0     0

errors: No known data errors
```

[Back to Partition Drive Helper Page](./partition_drive_helper_script.md)
