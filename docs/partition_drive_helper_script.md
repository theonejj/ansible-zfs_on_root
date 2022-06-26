# Helper Scripts

[Back to README.md](../README.md)

## partition_drive_helper.sh

As part of the ZFS on Root process, a script will be dynamically generated and stored located at `/root/partition_drive_helper.sh` which documents how the partitions were created and flags used to build the system.  

* This script will be handy in the future when you need to replace a drive and have to create new partitions on that drive to match the existing configuration.

---

## Examples

* [Failed Drive Replacement](./mark_swap_device_as_failed.md) - A full working example of rebuilding a complete drive including swap volumes.
* [Upgrade Working Drive to Larger Drive](upgrade_working_device.md) - A full working example of replacing a working (non-failed drive) in way that does not degrade pool state or redundancy.
* [Convert Single Device to ZFS Mirror](./convert_single_to_mirror.md) - Convert an initial single ZFS on Root installation to a ZFS Mirrored boot and root pools.

[Back to README.md](../README.md)
