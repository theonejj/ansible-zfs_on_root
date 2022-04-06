# ZFS on Root For Ubuntu 20.04 LTS

This Ansible role is my standardized ZFS on Root installation that I use as a base for all my systems.  Additional roles are applied on top of this to make the generic host a specialized Home Theater PC, Full Graphical Desktop, Kubernetes Cluster node, a headless Docker Server, etc...

_NOTE: This Ansible role is not structured as rigid as a typical Ansible role should be.  Tips and suggestions on how to improve this are welcomed._

---

Automated 'ZFS on Root' based on [OpenZFS Ubuntu 20.04 recommendations](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html#overview) with many enhancements:

* Predefine rules for ZFS `bpool` and `rpool` pools types (mirror, raidz1, raidz2, multiple mirror vdevs) based on number of devices available
* Swap partitions can be enabled
  * Multi-disk swap partitions automatically setup with `mdadm`
  * If encryption is enabled, LUKS is used to encrypt Swap partitions
* Native ZFS Encryption Support
* UEFI and Legacy Boot Partitions
* Multiple non-root user account creation
* Customized SSH Configuration Options
* DropBear support for unlocking remote ZFS encrypted pools

---

## TL;DR

* **Review know issues at the bottom.**  There is a "rpool" busy condition introduced with Ubuntu 20.04.03 and newer that I've not been able to resolve which results in a Ansible failure and manual interaction is required.
* This Ansible based process is intended to be used against bare-metal systems or virtual machines (just needs SSH access to get started)
* This uses ENTIRE disk(s) and wipes partitions on the specified disks, any existing data on these partitions on the target system will be lost
* Review the `defaults/main.yml` to set temporary passwords,  non-root user account(s) and basic rules on boot partition sizes, swap partitions, etc.
* Defaults to building a headless server environment, however a full graphical desktop can be enabled

---

## Environments Tested

* Ubuntu 20.04.3 Live CD Boot on Bare Metal or within VirtualBox
* Ubuntu 20.04.4 Live CD Boot on Bare Metal or within VirtualBox

---

## Requirements

* [Ansible](https://www.ansible.com/) (Built with Ansible Core 2.12 or newer)
* [Ubuntu 20.04.4 "Focal" Live CD](https://ubuntu.com/download/desktop/) (20.04.4 LTS Desktop, DO NOT use server images)
  _NOTE: you can configure for command-line only server build, don't worry about using the Desktop image._
* Installing on a drive which presents 4 KiB logical sectors (a “4Kn” drive) only works with UEFI booting. This not unique to ZFS. GRUB does not and will not work on 4Kn with legacy (BIOS) booting.
* Computers that have less than 2 GiB of memory run ZFS slowly. 4 GiB of memory is recommended for normal performance in basic workloads.

## Caution

* This process uses the whole physical disk
* This process is not compatible with dual-booting
* Backup your data. **Any existing data will be lost!**

---

## WHY use THIS instead of Ubuntu's Installation Wizard

### Configurable Rules

This provides a configurable way to define how the ZFS installation will look like and allows for topologies that cannot be defined within the standard Ubuntu installation wizard.  

* For example:
  * If you always want a 3 disk setup to have a _mirrored_ boot pool with a _raidz_ root pool, but a 4 disk setup should use a _raidz_ boot pool and multiple _mirrored_ vdev based root pool you can define these defaults.
* The size of boot and swap partitions can be defined to a standard value for single device and mirrored setups or a different value for raidz setup.
* UEFI Booting can be enabled and will be used when detected, it will fall back to Legacy BIOS booting when not detected.
* The installation is configurable to be a command-line only (server build) or Full Graphical Desktop installation.

### Optional ZFS Native Encryption

[ZFS Native Encryption](docs/zfs-encryption-settings.md) (aes-256-gcm) can be enabled for the root pool. If create swap partition option is enabled, then the swap partition will also be encrypted. The boot pool can not be encrypted natively and this script does not use LUKS encryption. From the [OpenZFS overview](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html#encryption):

* ZFS native encryption encrypts the data and most metadata in the root pool. It does not encrypt dataset or snapshot names or properties.
* The boot pool is not encrypted at all, but it only contains the bootloader, kernel, and initrd. (Unless you put a password in /etc/fstab, the initrd is unlikely to contain sensitive data.)
* The system cannot boot without the passphrase being entered at the console. [Dropbear with Busybox](docs/dropbear-busybox-settings.md) support can be enabled to allow remote SSH access at boot to enter passphrase remotely.

### SSHD Configuration Settings

Some of the [SSHD configuration](docs/custom-sshd-settings.md) options can be defined to help lock down your base server image. For example, Password Authentication will be disabled, Pubkey Authentication will be enabled, Root login will only be permitted via PubKey Authentication.

### Dropbear Support

When the server is rebooted with ZFS native encryption enabled then someone needs to be at the console to enter the passphrase for the root pool encryption.  

* You can enable the option to install [Dropbear](https://en.wikipedia.org/wiki/Dropbear_(software)) with [Busybox](https://en.wikipedia.org/wiki/BusyBox) to provide a lightweight SSH process as part of the initramfs during the boot process.  
* This allows you to remotely SSH to the console to provide the Root Pool passphrase to allow the machine to continue to boot.  
* You can customize the port, which RSA keys are allowed to connect and customize the options.  The default settings used are as secure as we could make it, and more secure than most guides.

All of this can be used to define a standard base installation for which other Ansible playbooks would build upon to make it a Home Theater PC, Docker Server, or just leave it as a functioning desktop.  

My intention for this was the occasional one off build, however being based on Ansible this can be used to make batches of servers or desktops needing ZFS on Root installations.

---

## How do I set it up

### Edit your inventory document

I use a `yaml` format inventory file, you will have to adjust to whatever format you use.

```yaml

---
###[ Define all Hosts ]########################################################
all:
  hosts:
    ...

  children:
    ###[ ZFS on Root Installs ]################################################
    zfs_on_root_install_group:
      hosts:
        testlinux01.localdomain:
          host_name: "testlinux01"
          disk_devices: ["sda", "sdb", "sdc"]
        testlinux01.localdomain:
          host_name: "testlinux02"
          disk_devices: ["sda", "nvme0n1"]

      vars:
        # Define the default domain these hosts will use
        domain_name: "localdomain"
```

* The `zfs_on_root_install_group:` block lists the hostname(s) that you intend to boot the Live CD on and perform a ZFS on Root installation.
* The `host_name:` is optional, defines the name of the new system to be built, if set here you will not be prompted for it
* The `disk_device:` is optional, you can specify on command line or be prompted for it.  This defines the name of the disk devices to use when building the ZFS pools if you know them in advance.  
  * When this is set you will not be prompted.
  * Default rules will make 2 devices a mirror, 3 will use a raidz1, 4 will join two mirrored vdevs into a pool (you can redefine these)
* The `domain_name:` under `vars:` sets the domain name that will be used for each host created.  If an individual host needs a different domain name then just add a `domain_name:` under that host.

---

### Edit `defaults/main.yml` to define the defaults

The `defaults/main.yml` contains most setting that can be changed.  

You are  defining reasonable defaults.  Individual hosts that need something a little different can be set in the inventory file or you can use any other method that Ansible support for defining variables.

#### Define Temporary Root Password

This temporary root password is only used during the build process.  The ability for root to use a password will be disabled towards the final stages.

```yml
###############################################################################
# User Settings
###############################################################################

# This is a temporary root password used during the build process.  
# Root password will be disabled during the final stages.
# The non-root user account will have sudo privileges
default_root_password: "change!me"
```

#### Define the Non-Root Account(s)

 Define your standard privileged account(s).  The root account password will be disabled at the end, the privileged account(s) defined here must have `sudo` privilege to perform root activities.  Additional accounts can be defined.

```yaml
# Define non-root user account(s) to create (home drives will be its own dataset)
# Each user will be required to change password upon first login
regular_user_accounts: 
  - user_id: "rich"
    password: "change!me"
    full_name: "Richard Durso"
    groups: "adm,cdrom,dip,lpadmin,lxd,plugdev,sambashare,sudo"
    shell: "/bin/bash"
```

### Additional Settings to Review

* Review [SWAP Partition Settings](docs/swap-partition-settings.md)
* Review [Boot Pool & Partition Settings](docs/boot-partition-settings.md)
* Review [Root Pool & Partition Settings](docs/root-partition-settings.md)
* Review [ZFS Native Encryption Settings](docs/zfs-encryption-settings.md)
* Review [Custom SSHD Configuration Settings](docs/custom-sshd-settings.md)
* Review [DropBear with Busybox Settings](docs/dropbear-busybox-settings.md)

#### UEFI or Legacy BIOS

Select if UEFI or Legacy BIOS is needed. When available UEFI will be used, if not available it will automatically fallback to BIOS.  If you never want to use UEFI then set this to false.

```yaml
###############################################################################
# Use Grub with UEFI (will do Grub with Legacy BIOS if false)
use_uefi_booting: true
```

#### CLI or Full Desktop

Select if Full Graphical Desktop or Command Line Server only.

```yaml
# For Full GUI Desktop installation (set to false) or command-line only server environment (set to true)
command_line_only: true
```

#### Define Locale and Timezone

Set your locale and timezone information.

```yaml
# Define the local pre-fix to enable in /etc/locale.gen
locale_prefix: "en_US"

# Define the timezone to be placed in /etc/timezone
timezone_value: "America/New_York"
```

#### Disable IPv6 Networking

By default IPv6 networking will be disabled.  If you have a need for it, you can set `ipv6.disable: false`

```yml
# Disable IPv6 if you do not use it.  The "disable_settings" will be applied to
# "conf_file"
ipv6:
  disable: true
  conf_file: "/etc/sysctl.d/99-sysctl.conf"
  disable_settings:
    - "net.ipv6.conf.all.disable_ipv6 = 1"
    - "net.ipv6.conf.default.disable_ipv6 = 1"
    - "net.ipv6.conf.lo.disable_ipv6 = 1"
  apply_cmd: "sysctl -p"
```

#### Define the ZFS Pool Names

These are the default names typically used on Ubuntu systems.  Other systems use other names.  Some people really can't sleep well at night if the pools don't have the perfect name.

 _NOTE: Within the ZFS on Root recommendations for Ubuntu 20.04, the `boot` pool name is no longer arbitrary. The boot pool name of `bpool` is required. The `rpool` name can be altered._

```yaml
# Define Pool Names
boot_pool_name: "bpool"
root_pool_name: "rpool"
```

### Additional Configuration Files

There should be no reason to alter the configuration file `vars/main.yml` which defines all the details and flags to construct partitions, root and boot pools, all the dataset that will be created.  If this type of information interests you, this is where you will find it... but don't change anything unless you understand what you are looking at.

---

## How do I Run It

### Prepare the Install Environment

1. Boot the Ubuntu Live CD:
    * Select option <button name="button">Try Ubuntu</button>.
    * Connect your system to the Internet as appropriate (e.g. join your Wi-Fi network).
    * Open a terminal within the Live CD environment - press <kbd>Ctrl</kbd> <kbd>Alt</kbd>-<kbd>T</kbd>.

2. Install and start the OpenSSH server in the Live CD environment (see helper script below):

#### Fetch Helper Script

The helper script will perform many steps for you such as update packages, create an `ansible` user account, define a password for that account, grant the `ansible` account `sudo` privileges, install SSH server, python, etc.

```bash
wget https://raw.githubusercontent.com/reefland/ansible-zfs_on_root/master/files/do_ssh.sh

chmod +x do_ssh.sh

./do_ssh.sh
```

* When prompted for the Ansible password, enter and confirm it.  This will be a temporary password only needed just to push the SSH Key to the target machine.  The Ansible password will be disabled and only SSH authentication will be allowed.

#### If Helper Script is not Available

These are the manual commands performed by the helper script.  If it is not available, these steps do the same.

```bash
sudo apt-add-repository universe
sudo apt update

sudo useradd -m ansible
sudo passwd ansible

sudo visudo -f /etc/sudoers.d/99_sudo_include_file

ansible ALL=(ALL) NOPASSWD:ALL

# Save File & Exit

sudo apt install --yes openssh-server vim python3 python3-apt
sudo swapoff -a

gsettings set org.gnome.desktop.media-handling automount false

```

The Live CD Install Environment is now ready.  Nothing else you need to do here.  The rest is done from the Ansible Control node.

### Push your Ansible Public Key to the Install Environment

From the Ansible Control Node push your ansible public key to the Install Environment.
You will be prompted for the ansible password create within Ubuntu Live CD Install Environment:

```bash
ssh-copy-id -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -i ~/.ssh/ansible.pub ansible@<remote_host_name>

# Expected output:
ansible@<remote_host_name> password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ansible@<remote_host_name>'"
and check to make sure that only the key(s) you wanted were added.
```

Optionally, you can test connectivity easily to verify SSH has been configured correctly.

```bash
ansible -i inventory.yml -m ping <remote_host_name>

# Expect output to include:

remote_host_name | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

You are now ready to perform a ZFS on Root installation to this target machine.

### Fire-up the Ansible Playbook

The most basic way to run the entire ZFS on Root process and limit to an individual host as specified:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml -l <remote_host_name>
```

The following shows examples of overriding values from the command line. Typically it will be easier to define these in the inventory instead.

If a non-standard SSH port is required:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml -l <remote_host_name> -e "ansible_port=22"
```

To enable ZFS Native Encryption:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{passphrase: "mySecr3tPa55"}' -l <remote_host_name>
```

To define specific devices or a sub-set of available devices:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb]}' -l <remote_host_name>
```

To define an alternate hostname (other than one used for SSH connection):

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{host_name: testlinux}' -l <remote_host_name>
```

To enable some debug or verbose output:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{debug: on}' -l <remote_host_name>

# To enable ansible verbose details as well:
ansible-playbook -vvvv -i inventory.yml ./zfs_on_root.yml --extra-vars='{debug: on}' -l <remote_host_name>
```

To do multiple of these at the same time:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb], host_name: testlinux, passphrase: "mySecr3tPa55"}' -l <remote_host_name>
```

If the above is too complicated, no worries.  The script will show you the detected defaults and let you just type values.  It will also show you a summary screen of values for your reference and allow you to abort.

---

### Step by Step Installation

As an alternative to running the entire playbook at one time, it can be run sections at a time using the ansible `tags` as defined below.  This method can be used to troubleshoot issues and replay steps if you have a way of rolling back previous failures. Failures can be rolled back either manually or via snapshots in Virtualbox or equivalent.

To run just one stage via tags, all the Ansible Playbook examples from above can be used with the addition of including tags:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb], host_name: testlinux}' -l <remote_host_name> --tags="install-zfs-packages"
```

Multiple tags can be combined to run several tasks:

```text
--tags="create_pools, create_filesystems, create_datasets"
```

This is the list and order of execution for all tags defined for this playbook:

```text
    tags:
      - install-zfs-packages
      - clear_partition_tables_from_devices
      - create_partitions
      - create_pools
      - create_filesystems
      - create_datasets
      - config_system
      - config_boot_fs
      - config_grub
      - config_swap
      - system_tweaks
      - install_grub
      - fix_mount_order
      - first_boot_prep
      - unmount_chroot
      - restart_remote
      - grub_uefi_multi_disk
      - create_regular_user
      - full_install
      - disable_ipv6
      - restart_remote_final
      - install_drop_bear
      - final_cleanup
      - update_sshd_settings
```

Helper tasks, basic sanity checks and mandatory tasks are already marked as `always` and will always be processed to setup the base ansible working environment reading configuration files, setting variables, etc... nothing special you need to do.

---

## Known Issues

### Issue #1 - Task: zfs_on_root : Export all ZFS Pools - Fails

```text
STDERR:
cannot export 'rpool': pool is busy
```

It can be very difficult to nearly impossible to determine why a pool is busy at such an early stage in the build process.  All mounts are removed, no datasets are shared yet, no users are within the mounted areas. Without being able to export the pool cleanly during this process, importing the pool will fail upon first reboot.  The following work around imports the pool and allows you to resume the boot process.

#### Workaround for Issue #1

* Power down Live CD Environment
* Remove LiveCD media
* Power up instance

The following error message is now expected during the boot process:

```bash
Importing pool 'rpool' using cachefile. ... Failure 1

Message: cannot import 'rpool': no such pool available
Error: 1

Failed to import pool 'rpool'.
Manually import the pool and exit.
```

At the `(initramfs)` prompt, type the following:

```bash
zpool import -f rpool
exit
```

The system should now resume booting. If ZFS Encryption is enabled it will prompt for the passphrase to unlock the pool.

Then:

* Login as root
* Reboot the system again
* Confirm it boots cleanly without the pool import error

To resume the ansible playbook, you can specify to execute the remaining steps via ansible tags (all at once, or specify one, or a few at a time -- your choice).

```text
--tags="grub_uefi_multi_disk, create_regular_user, full_install, disable_ipv6, restart_remote_final, final_cleanup, install_drop_bear, update_sshd_settings"
```

If root pool encryption was being used, include this variable to trigger steps which need to act on it:

```text
--extra-vars='root_pool_encryption=true'
```

---

### Issue #2 - Multi-disk SWAP using `mdadm` is not mounted as `/dev/md0` and thus no swap space

```bash
$ cat /proc/swaps 
Filename                             Type       Size    Used    Priority

$ free -mh | grep Swap
Swap:         0B          0B       0B
```

If there is anything incorrect with the configuration file `/etc/mdadm/mdadm.conf` the kernel will attempt to assemble the array and mount it as something like `/dev/md127` the swap is configured to be at `/dev/md0` and will not work until this is corrected.

#### Workaround for Issues #2

Confirm the device name of the incorrect mdadm device with:

```bash
cat /proc/mdstat 

md127 : active (auto-read-only) raid5 sda2[0] sdc2[3] sdb2[1]
      2093056 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
```

Stop the incorrectly named device:

```bash
sudo mdadm -S /dev/md127
```

Assemble Array with correct name `/dev/md0` include the device names listed above, they will always end with a `2` based on how ZFS on Root sets up partitions.

```bash
mdadm -Av --update=name --run /dev/md0 /dev/sda2 /dev/sdb2 /dev/sdc2
```

Confirm the mdadm device name is now correctly showing `md0`:

```bash
cat /proc/mdstat 

md0 : active raid5 sda2[0] sdc2[3] sdb2[1]
  2093056 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
```

This updates the mdadm configuration file. This needs to be added to the kernel initramfs image as follows:

```bash
update-initramfs -c -k all
```

* Reboot the system

SWAP space should now be functional:

```bash
$ cat /proc/swaps 
Filename                                Type            Size    Used    Priority
/dev/dm-0                               partition       2093052 0       -2

$ free -mh | grep Swap
Swap:         2.0Gi          0B       2.0Gi
```

---

## More about Root Pool using Mirrored vdev Process

This topology is not available from Ubuntu installer and is not covered by the [OpenZFS HowTo method](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html#overview).

Here is a brief [overview with additional information](docs/root-pools-multi-mirrored-vdevs.md).

---

## Helper Scripts

### do_ssh.sh

Once the Ubuntu Live CD is booted on the target system, there are a number of steps you need to perform to allow ansible to connect to it over the network such as update packages, create an ansible user account, define a password, grant the ansible account `sudo` privileges, install SSH server, etc.  The helper script named `do_ssh.sh` completes all this work for you.  Simply use `wget` to fetch the file, use `chmod +x do_ssh.sh` to make it executable and run it `./so_ssh.sh` that's all.

```bash
wget https://gitea.rich-durso.us/reefland/ansible/raw/branch/master/roles/zfs_on_root/files/do_ssh.sh

chmod +x do_ssh.sh

./do_ssh.sh
```

---

### partition_drive_helper.sh

As part of the ZFS on Root process, a script will dynamically generated located in `/root` named `partition_drive_helper.sh` which documents how the partitions were created and flags used to build the system.  This script will be handy in the future when you need to replace a drive and have to create new partitions on that drive to match the existing configuration.

#### Marking Swap Device as Failed

NOTE: `mdadm` is used to create mirrored or striped swap partitions.  If you will be replacing a drive then you should mark the device as **failed** before removing it from the system. Failure to do so will likely result in no swap being available.  Marking the device as failed before removal allows the swap device to function even if in a degraded state.

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

The `partition_drive_helper.sh` script can help you go from a blank replacement device to a fully repaired system.  

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

    If partitions exits, the partitions must be removed first.  The output would like something like the following:

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
