# Helper Scripts

[Back to README.md](../README.md)

## partition_drive_helper.sh

As part of the ZFS on Root process, a script will be dynamically generated and stored located at `/root/partition_drive_helper.sh` which documents how the partitions were created and flags used to build the system.  

* This script will be handy in the future when you need to replace a drive and have to create new partitions on that drive to match the existing configuration.

A full working example of rebuilding a complete drive including swap volumes is [documented here](./mark_swap_device_as_failed.md).

[Back to README.md](../README.md)
