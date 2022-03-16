# ROOT Partition Settings

[Back to README.md](../README.md)

## Root Partition Size

* The root partition size will decided by ZFS at pool creation to use the largest possible value.  
  * If devices of different size are used then the size of the RPOOL will be limited to the space left on the smallest device
  * Any remaining space will be unallocated.
    You can leave it as-is  until the smaller device is replaced in the future and pool expansion can be used at that point
  * You can create your own additional pools with the unallocated space

---

## Root Partition Type Rules

Define ZFS Root Pool Type Rules. Similar rules apply here as applied to the [boot pool](boot-partition-settings.md). Key differences:

* Any EVEN number of devices (2, 4, 6, 8..), specified to be a `mirror` will be a mirrored vdev pair (which is awesome!)
  * This is the recommended way to configure ZFS with many devices instead of using `raidz`
  * This is higher performance and much fastest recovery from a single disk failure
  * This topology is not available from Ubuntu installer or with the OpenZFS HowTo method.
    * See more details on Mirrored vdev Root Pools
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

[Back to README.md](../README.md)
