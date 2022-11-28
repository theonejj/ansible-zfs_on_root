# ROOT Partition Settings

[Back to README.md](../README.md)

## Define the ZFS Pool Name

This is the default name to be assigned to the ZFS pool.  Some people really can't sleep well at night if their ZFS pools don't have the perfect name.

```yaml
# Define Pool Names - can be set to whatever you like.
# Short hostname is default, this is like "rpool" in the previous methods.
root_pool_name: "{{ host_name }}"
```

Based on the name above then:

* User data will be stored in ZFS Dataset: `host_name/ROOT/home`
* Operating System is within ZFS Dataset: `host_name/ROOT/ubuntu`

NOTE: The Operating System dataset has automatically snapshots created when `apt` or `dpkg` installs or removes packages. This allows the OS to be rolled back to previous snapshots without impacting user data.

## Root Partition Size

* By default the root partition size will decided by ZFS at pool creation to use the largest possible value.  
  * If devices of different size are used then the size of the RPOOL pool will be limited to the space left on the smallest device.
* You can specify a specific partition size for the rpool on each device in the storage pool. This is useful if you want a standard size partitions on each computer.
* Or you can specify how much space NOT to use leaving a specific amount of unallocated space for some other use.

  ```yaml
  ###############################################################################
  # The root pool by default will consume all remaining disk space on the devices
  # limited by the free space of the smallest device specified.  For example a
  # mirror between a 512GB and 256GB device cannot be larger than the capacity of
  # the smaller device.

  # If you wish to limit the root pool size leaving unused space, you can define
  # that here.  Specify how much space to allocate or NOT allocate per root pool
  # partition per device.

  # Examples:
  # "+256G" will create partitions 256Gib in size
  # "-200M" will use all available space, minus 200Mib
  # "0" (zero) use all available space
  root_partition_size: "0"
  ```

* If you decided to have unallocated space left, the remaining storage space will be after the last partition created. This simplifies making additional partitions later or expanding expanding partitions later.

---

## Root Partition Type Rules

Define ZFS Root Pool Type Rules. Similar rules apply here as applied to the [boot pool](boot-partition-settings.md). Key differences:

* Any EVEN number of devices (2, 4, 6, 8..), specified to be a `mirror` will be a [mirrored vdev pair](root-pools-multi-mirrored-vdevs.md) (which is awesome!)
  * This is the recommended way to configure ZFS with many devices instead of using `raidz`
  * This is higher performance and much fastest recovery from a single disk failure
  * This topology is not available from Ubuntu installer or with the OpenZFS HowTo method.

  * If you don't want this, then use `raidz` or `raidz2` type
* Any ODD number of devices should be a `raidz` or `raidz2` type
  * A `raidz2` can be tried with 4 or more devices, but `raidz2` is not recommended.

  ```yaml
  # Define the root pool type based on number of devices.
  #  - If you want 3 devices to be a 3 way mirror change it, etc.
  #  - If even number 2,4,6,8, etc of type mirror, then mirrored vdevs will be used.
  #  - -  This is higher performance with redundancy and much faster resilver times
  #  - -  than using any type of raidz.
  #  - Raidz will be the default if something below is not defined.
  #  - NOTE: A raidz2 requires 4 or more devices.
  set_root_pool_type:
    1: ""
    2: "mirror"
    3: "raidz"
    4: "mirror"
    5: "raidz"
    6: "mirror"
    default: "raidz"
  ```

## Ashift Value

The ZFS `ashift` value for modern devices with 512 byte or 4K sector size should be `12`.  Some flash devices could see better performance with `13` as internally they might be 8K devices.  Many devices simply lie about what they truly are due compatibility reasons.

```yml
# Define ZFS ashift value to use
zfs_rpool_ashift: 12
```

* If `ashift` is too high, you lose a bit of space if you have a massive amount of very small files. If it’s too low, you get write amplification and performance degradation.

[Back to README.md](../README.md)
