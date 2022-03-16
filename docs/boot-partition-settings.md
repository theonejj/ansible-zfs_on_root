# BOOT Partition Settings

[Back to README.md](../README.md)

## Boot Partition Size

* If a `single device` or a `mirror` boot pool is used then boot partition will be a fixed size across all devices (meaning if you define 2048 MB then it will be that size).  
* If boot pool is a `raidz` then size can be estimated to be `((number of devices-1) x raidz_boot_partition_size_MB)`

```yaml
###############################################################################
# A Boot Pool should be in the 1024MB to 2048MB size (larger is fine).
# Smaller sizes can cause issue later when kernels are upgraded.

# Boot Partition size when a single device or set_boot_pool_type is mirror
single_or_mirror_boot_partition_size_MB: "2048"

# Partition size, per device, when multiple devices are used
# If set_boot_pool_type is raidz, then is will be a mdm raid5 of this size in MB (#devices-1*size_MB)
# The more devices used, the smaller these values can be to get the same size.
raidz_boot_partition_size_MB: "768"
```

_NOTE: A boot partition size calculated to be between 1.5 Gib (1430 MiB) to 2 Gib (1907 MiB) is a reasonable starting range.  Larger is fine, but smaller size may have an issue in the future trying to process kernel upgrades._

---

## Boot Partition Type Rules

Define ZFS Boot Pool Type Rules (based on number of storage devices detected)

* When one device is used, it is nothing special and no defined keyword needed. Leave it blank.
* Two devices can only use a `mirror`, don't change it.
* Three or four devices could be a `mirror` or `raidz`, your preference.
* Any number not defined here will be of typed stated in the `default` value.

```yaml
###############################################################################
# ZFS Specific Adjustable Settings
###############################################################################

# Define the boot pool type based on number of devices.
#  - If you want 3 devices to be a 3 way mirror change it, etc.
#  - Raidz will be the default if something below is not defined.
set_boot_pool_type:
  1: ""
  2: "mirror"
  3: "raidz"
  4: "raidz"
  default: "raidz"
```

_NOTE: a boot pool of type `raidz2` or `raidz3` is technically possible, but not supported or implemented by this script. Don't try it, unexpected results and failure will happen._

[Back to README.md](../README.md)
