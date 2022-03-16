# Swap Partition Settings

[Back to README.md](../README.md)

NOTE: The swap partition will follow whatever the `boot` pool configuration rules are.

* If a `single device` or a `mirror` boot pool is used then swap partition will be a `mdadm` based mirror (fixed size) across all devices (meaning if you define 4096 MB then it will be that size).  
* If boot pool is a `raidz` then swap will be a `mdadm` based RAID5 stripe across the disk devices.  The swap size can be estimated to be `((number of devices-1) x raidz_swap_partition_size_MB)`

_NOTE: Per ZFS on Root recommendations for Ubuntu 20.04, swap partitions should not reside on ZFS partitions or zvols due to reports of ZFS deadlocks with swap.  Thus `mdadm` will be used for `mirrored` or `raid` based swap configurations._

```yaml
###############################################################################
# Computer Configuration Settings
###############################################################################
# Create Swap Partitions
enable_swap_partitions: true

# NOTE: For hibernation you need at least as much swap as the system RAM
#       Hibernation does not work with encrypted swap.

# Swap partition size when a single device or set_boot_pool_type is mirror
single_or_mirror_swap_partition_size_MB: "4096"

# Partition size, per device, when multiple devices are used
# If set_boot_pool_type is raidz, then is will be a mdm raid5 of this size in MB (#devices-1*size_MB)
# The more devices used, the smaller these values can be to get the same size.
raidz_swap_partition_size_MB: "1024"
```

[Back to README.md](../README.md)
