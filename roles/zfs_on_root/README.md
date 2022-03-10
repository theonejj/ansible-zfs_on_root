# ZFS on Root with Ubuntu

Automated 'ZFS on Root' based on [OpenZFS Ubuntu 20.04 recommendations](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html#overview) with many enhancements.

## Requirements

* [Ansible](https://www.ansible.com/) (Built with Ansible Core 2.12)
* [Ubuntu 20.04.3 "Focal" Live CD](https://ubuntu.com/download/desktop/) (20.04.3 LTS Desktop, DO NOT use server images)
  _NOTE: you can configure for command-line only server build, don't worry about using the Desktop image._
* Installing on a drive which presents 4 KiB logical sectors (a “4Kn” drive) only works with UEFI booting. This not unique to ZFS. GRUB does not and will not work on 4Kn with legacy (BIOS) booting.
* Computers that have less than 2 GiB of memory run ZFS slowly. 4 GiB of memory is recommended for normal performance in basic workloads.

## Caution

* This process uses the whole physical disk.
* This process is not compatible with dual-booting.
* Backup your data. Any existing data will be lost.

## WHY use THIS instead of Ubuntu's Installation Wizard

### Configurable Rules

This provides a configurable way to define how the ZFS installation will look like and allows for topologies that cannot be defined within the standard Ubuntu installation wizard.  

* For example, if you always want a 3 disk setup to have a _mirrored_ boot pool with a _raidz_ root pool, but a 4 disk setup should use a _raidz_ boot pool and multiple _mirrored_ vdev based root pool you can define these defaults.
* The size of boot and swap partitions can be defined to a standard value for single device and mirrored setups or a different value for raidz setup.
* UEFI Booting can be enabled and will be used when detected, it will fall back to Legacy BIOS booting when not detected.
* The installation is configurable to be a command-line only (server build) or Full Graphical Desktop installation.

### Optional ZFS Native Encryption

ZFS Native Encryption (aes-256-gcm) can be enabled for the root pool. If create swap partition option is enabled, then the swap partition will also be encrypted. The boot pool can not be encrypted natively and this script does not use LUKS encryption. From the [OpenZFS overview](https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2020.04%20Root%20on%20ZFS.html#encryption):

* ZFS native encryption encrypts the data and most metadata in the root pool. It does not encrypt dataset or snapshot names or properties.
* The boot pool is not encrypted at all, but it only contains the bootloader, kernel, and initrd. (Unless you put a password in /etc/fstab, the initrd is unlikely to contain sensitive data.)
* The system cannot boot without the passphrase being entered at the console. Dropbear with Busybox support can be enabled to allow remote SSH access at boot to enter passphrase remotely.

### SSHD Configuration Settings

Some of the SSHD configuration options can be defined to help lock down your base server image. For example, Password Authentication will be disabled, Pubkey Authentication will be enabled, Root login will only be permitted via PubKey Authentication.

### Dropbear Support

When the server is rebooted with ZFS native encryption enabled then someone needs to be at the console to enter the passphrase for the root pool encryption.  

* You can enable the option to install [Dropbear](https://en.wikipedia.org/wiki/Dropbear_(software)) with [Busybox](https://en.wikipedia.org/wiki/BusyBox) to provide a lightweight SSH process as part of the initramfs during the boot process.  
* This allows you to remotely SSH to the console to provide the Root Pool passphrase to allow the machine to continue to boot.  
* You can customize the port, which RSA keys are allowed to connect and customize the options.  The default settings used are as secure as we could make it, and more secure than most guides.

All of this can be used to define a standard base installation for which other Ansible playbooks would build upon to make it a Home Theater PC, Docker Server, or just leave it as a functioning desktop.  My intention for this was the occasional one off build, but being based on Ansible this can be used to make batches of servers or desktops needing ZFS on Root installations.

---

## How do I set it up

### Edit your inventory document

Add something like the following:

```ini

[zfs_on_root_install_group:vars]
ansible_ssh_common_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
ansible_user=ansible
ansible_ssh_private_key_file=/home/rich/.ssh/ansible

[zfs_on_root_install_group]
testlinux.example.com  host_name="testlinux" disk_device='["sda", "sdb", "sdc"]'
```

* The `[zfs_on_root_install_group:vars]` block defined the SSH connection.  If you have this defined elsewhere such as in `.ansible.cfg` then this can be omitted.  
* The `[zfs_on_root_install_group]` block lists the hostname(s) that you intend to boot the Live CD on and perform a ZFS on Root installation.
* The `host_name=` is optional, if set you will not be prompted for it
* The `disk_device=` is optional, you can specify on command line or be prompted for it.  This defines the name of the disk devices to use when building the ZFS pool if you know them in advance.  If this is set you will not be prompted for this.

### Edit `defaults/main.yml` to define the defaults

1. Define your standard privileged account.  The root account password will be disabled at the end, the privileged account will have `sudo` privilege to perform root activities.

    ```yaml
    ###############################################################################
    # User Specific Settings
    ###############################################################################

    # Default root password to set - temporary, password is disabled at end.
    # The non-root user account will have sudo privileges
    default_root_password: "change!me"

    # Define non-root usr account to create (home drive will be its own dataset)
    regular_user_account: "rich"
    regular_user_password: "change!me"
    regular_user_fullname: "Richard Durso"
    regular_user_groups: "adm,cdrom,dip,lpadmin,lxd,plugdev,sambashare,sudo"
    regular_user_shell: "/bin/bash"
    ```

2. Define SWAP Partition Settings. The swap partition will follow the `boot` pool configuration rules.

    * If a `single device` or a `mirror` boot pool then swap partition will be a `mdadm` based mirror (fixed size) across all devices (meaning if you define 4096 MB then it will be that size).  
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

3. Define BOOT Partition Settings.

    * If a `single device` or a `mirror` boot pool then boot partition will be a fixed size across all devices (meaning if you define 2048 MB then it will be that size).  
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

4. Next select if UEFI or Legacy BIOS is needed, and select if Full Graphical Desktop or Command Line Server only.  To force Ansible to set a ZFS encryption password set that option to `true`. You can also set your locale and timezone information here.

    ```yaml
    ###############################################################################
    # Use Grub with UEFI (will do Grub with Legacy BIOS if false)
    use_uefi_booting: true

    # For Full GUI Desktop installation (set to false) or command-line only server environment (set to true)
    command_line_only: true

    # Prompt for Native ZFS Encryption Passphrase.  if true, then prompt for passphrase if not provided.
    prompt_for_zfs_passphrase: true

    # Define the local pre-fix to enable in /etc/locale.gen
    locale_prefix: "en_US"

    # Define the timezone to be placed in /etc/timezone
    timezone_value: "America/New_York"
    ```

5. Define ZFS Boot Pool Type Rules (based on number of storage devices detected)

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

6. Define ZFS Root Pool Type Rules

    Similar rules apply here as applied for boot pool. Key differences:

    * Any EVEN number of devices, specified to be a `mirror` will be a mirrored vdev pair.  This is the recommended way to configure ZFS with many devices instead of using `raidz` for performance and fastest recovery from a single disk failure (this topology is not available from Ubuntu installer or covered with the OpenZFS HowTo method).  See below for more details on Mirrored vdev Root Pools.
    * Any ODD number of devices should be a `raidz` type. 
    * A `raidz2` can be tried with 4 more devices, but `raidz2` is not recommended.

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

7. Define the pool names

    These are the default names typically used on Ubuntu systems.  Other systems use other names.  Some people really can't sleep well at night if the pools don't have the perfect name.

    ```yaml
    # Define Pool Names
    boot_pool_name: "bpool"
    root_pool_name: "rpool"
    ```

    _NOTE: Per ZFS on Root recommendations for Ubuntu 20.04, the `boot` pool name is no longer arbitrary. It must be `bpool`._

## Additional Configuration Files

There should be no reason to alter the configuration file `vars/main.yml` which defines all the details and flags to construct partitions, root and boot pools, all the dataset that will be created.  If this type of information interests you, this is where you find it... but don't change anything unless you understand what you are looking at.

## How to Enable Native ZFS Encryption

### Option One

To enable ZFS encryption, a passphrase can be specified using the Ansible command line parameter `--extra-vars` such as:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{passphrase: "mySecr3tPa55"}'

```

The specified `passphrase` will define the boot password needed to decrypt the root pool.  The system is not bootable until the correct password is entered to decrypt the pool.  

### Option Two

Within the `defaults/main.yml` you can make ZFS Native Encryption password required.  If this option is set to true and one is not defined on the command line as per instructions above you will be prompted to enter a passphrase.

```yaml
# Prompt for Native ZFS Encryption Passphrase.
prompt_for_zfs_passphrase: true
```

_NOTE: Any Ansible method to define the variable `passphrase` will be enough to trigger the script to reconfigure to support ZFS Native Encryption._

---

## How do I Run It

### Prepare the Install Environment

1. Boot the Ubuntu Live CD:
    * Select option <button name="button">Try Ubuntu</button>.
    * Connect your system to the Internet as appropriate (e.g. join your Wi-Fi network).
    * Open a terminal within the Live CD environment - press <kbd>Ctrl</kbd> <kbd>Alt</kbd>-<kbd>T</kbd>.

2. Clear out Existing Partitions

    The installation will do its best to clear partitions, however there are scenarios where they get in the way.  ZFS may try to mount volumes it detects that you plan on using for something else. Check if your data disks have partitions:

    ```bash
    $ lsblk

    sda                                             8:0    1   2.7T  0 disk  
    ├─sda1                                          8:1    1   2.7T  0 part  
    └─sda2                                          8:9    1     8M  0 part  
    sdb                                             8:16   1   2.7T  0 disk  
    ├─sdb1                                          8:17   1   2.7T  0 part  
    └─sdb2                                          8:25   1     8M  0 part 
    ```

    NOTE: Do not ERASE partitions of the Live CD environment! Just data disks you want to use.

    Press <kbd>ALT</kbd>-<kbd>F2</kbd> to run a command and enter `gparted`.  This program is used to remove existing partitions. Once Gparted has loaded:
      * Select the device
        * Press <kbd>ALT</kbd>-<kbd>D</kbd> for "Device"
        * Select "Create Partition Table"
        * Select Partition Type `gpt` and click <kbd>Apply</kbd>
      * Repeat this process for each data drive
      * Close Gparted
    Press <kbd>ALT</kbd>-<kbd>F2</kbd> to run a command and enter `reboot`
    After reboot this step can be skipped.


3. Install and start the OpenSSH server in the Live CD environment:

#### Fetch Helper Script

The helper script will perform many steps for you such as update packages, create an `ansible` user account, define a password for that account, grant the `ansible` account `sudo` privileges, install SSH server, python, etc.

```bash
wget https://gitea.rich-durso.us/reefland/ansible/raw/branch/master/roles/zfs_on_root/files/do_ssh.sh

chmod +x do_ssh.sh

./do_ssh.sh
```

When prompted for the Ansible password, enter and confirm it.  This will be a temporary password only needed just to push the SSH Key to the target machine.  The Ansible password will be disabled and only SSH authentication will be allowed.

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
ssh-copy-id -i ~/.ssh/ansible.pub ansible@<remote_host_name>

# Expected output:
ansible@<remote_host_name> password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ansible@<remote_host_name>'"
and check to make sure that only the key(s) you wanted were added.
```

Optionally, you can test connectivity easily to verify SSH has been configured correctly.

```bash
ansible -i inventory -m ping <remote_host_name>

# Expect output to include:

remote_host_name | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

You are now ready to perform a ZFS on Root installation to this target machine.

### Fire-up the Ansible Playbook

The most basic way to run the entire ZFS on Root process:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml -l <remote_host_name>
```

If a non-standard SSH port is required:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml -l <remote_host_name> -e "ansible_port=22"
```

To enable ZFS Native Encryption:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{passphrase: "mySecr3tPa55"}' -l <remote_host_name>
```

To define specific devices or a sub-set of available devices:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb]}' -l <remote_host_name>
```

To define an alternate hostname (other than one used for SSH connection):

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{host_name: testlinux}' -l <remote_host_name>
```

To enable some debug or verbose output:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{debug: on}' -l <remote_host_name>

# To enable ansible verbose details as well:
ansible-playbook -vvvv -i inventory ./zfs_on_root.yml --extra-vars='{debug: on}' -l <remote_host_name>
```

To do multiple of these at the same time:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb], host_name: testlinux, passphrase: "mySecr3tPa55"}' -l <remote_host_name>
```

If the above is too complicated, no worries.  The script will show you the detected defaults and let you just type values.  It will also show you a summary screen of values for your reference and allow you to abort.

### Step by Step Installation

Instead of running the entire playbook at one time, in can be run sections at a time using the ansible `tasks` as defined in `zfs_on_root.yml` file.  This method can be used to troubleshoot issues and replay steps if you have a way of rolling back previous failures. Failures can be rolled back either manually or via snapshots in Virtualbox or equivalent.

To run just one stage via tags, all the Ansible Playbook examples from above can be used with the addition of including tags:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb], host_name: testlinux}' -l <remote_host_name> --tags="install-zfs-packages"
```

Multiple tags can be combined to run a few things in a row by combining tags:

```text
--tags="create_pools, create_filesystems, create_datasets"
```

List and order of execution of tags defined for this playbook:

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
      - restart_remote
      - grub_uefi_multi_disk
      - create_regular_user
      - full_install
      - restart_remote_final
      - final_cleanup
      - install_drop_bear
```

Helper tasks, basic sanity checks and mandatory tasks are already marked as `always` and will always be processed to setup the base ansible working environment reading configuration files, setting variables, etc... nothing special you need to do.

---

## Customized SSHD Configuration

Some of the basic, more common SSHD Configuration settings can be updated.  Ansible does not have a specific module for updating `sshd_config`.  The grep rules in the helper task handle most of the `yes`, `no`, `numerical` such as 10, 22, or 2m.  More complex matches like IP addresses and directory paths are not handled.

```yaml
###############################################################################
# The following SSHD Settings will be applied at final_cleanup
# IMPORTANT: Only some basic settings which can be search and replaced using values
#            such as works such as: "yes", "no", "none", "any", "prohibit-password",
#             digits (such as 10, 22, or 2m). Does not match fancy items like
#            IP Address or full directory paths.
update_sshd_settings: true
apply_sshd_settings:
  PasswordAuthentication: "no"
  PermitRootLogin: "prohibit-password"
  PubkeyAuthentication: "yes"
```

Use `update_sshd_settings` within `defaults/main.yml` to enable (true) or disable (false) updating SSH entries.  Values can be changed and new values entries can be added. When ready changes can be  deployed (and `sshd` service will be restarted) using the following:

```bash
ansible-playbook -i inventory zfs_on_root.yml --tags="update_sshd_settings"
```

---

## Dropbear with Busybox Integrated

Dropbear with Busybox can be enabled in the `defaults/main.yml` by setting `enable_dropbear_with_busybox_support` to `true`. This enables a small SSH service at boot time to allow a connection to be made remotely to enter the native ZFS Encryption passphrase. Once entered the system will continue the boot up process.  If you are not using ZFS encryption then there is no need to enable or configure this.

```yaml
###############################################################################
# Dropbear support allows for small SSH service to be included in initram to allow
# for remote connection to enter the ZFS Native Encryption Password.
#
# NOTE: Dropbear's private keys will reside on the unencrypted boot volume. Someone
#       with physical access to the server would be able to discover the private
#       keys.
enable_dropbear_with_busybox_support: true
apply_dropbear_settings:
  NO_START: "0"
  DROPBEAR_PORT: "2222"
  DROPBEAR_EXTRA_ARGS: "-s -j -k -I 60 -c /bin/unlock"
```

The `NO_START` option `0` enables Dropbear and `1` disables.  The `DROPBEAR_EXTRA_ARGS` lock down the environment a bit and prevent an open shell. Only the `unlock` command is allowed and it will be run automatically upon connection.

If you need to troubleshoot why a remote unlock fails, then remove `-c /bin/unlock` from `DROPBEAR_EXTRA_ARGS`and run the playbook to deploy, then restart machine to take effect.  The `/bin/unlock` is a generated script which can be reviewed within the Dropbear shell.  The source of the script is defined within `templates/crypt_unlock.j2`.

The RSA Public keys that are authorized to connect to Dropbear are defined below.  It is questionable how compatible Dropbear is with ECSDA and DSS keys.  RSA Keys are well supported.

```yaml
# Define the full path to public key(s) you want to include in Dropbear
# NOTE: RSA based authentication is advised over ecdsa and dss.
#       To create key:  ssh-keygen -o -a 100 -b 3072 -t rsa -f ~/.ssh/dropbear_rsa  
rsa_public_key_for_dropbear:
  - "/home/rich/.ssh/dropbear_rsa.pub"
```

Additional restrictions are placed on each SSH public key listed above. The restrictions are defined with:

```yaml
# Shell Restrictions placed on each rsa_public_key_for_dropbear entry
dropbear_user_restriction: 'no-port-forwarding,no-agent-forwarding,no-x11-forwarding'
```

Dropbear with Busybox can be deployed and updated independently.  Don't bother forcing it to be installed on a system not using ZFS Native Encryption, there is nothing to prevent the boot up process which would require Dropbear and the unlock script will be of no use. The `crypt_unlock.j2` has been modified to work with ZFS and will not work with LUKS, etc.

If at some point in the future you wish to install Dropbear or update its configuration (perhaps add or replace RSA Public Keys) manually use:

```bash
ansible-playbook -i inventory zfs_on_root.yml --extra-vars='{passphrase: "dummypass"}' --tags="install_drop_bear"
```

_NOTE: The correct passphrase for an existing encrypted pool is not actually needed. The passphrase variable just needs to be set for the workflow to be triggered._

To establish an `SSH` connection to a remote system with Dropbear installed, using your Dropbear specific RSA Key to connect as root:

```bash
$ ssh -i ~/.ssh/dropbear_rsa -p 2222 root@<remote_host_name>
Enter passphrase for 'rpool':
1 / 1 key(s) successfully loaded
ZFS Root Pool Decrypted
Connection to <remote_host_name> closed.
```

The only thing you'll be prompted for is the passphrase to decrypt the root pool. If entered incorrectly you will be given additional attempts.  Once entered correctly the connection is closed and system boot sequence proceeds.  The Dropbear SSH service will not be running once the system has booted.

---

## Known Issues

1. Task: zfs_on_root : Export all ZFS Pools - Fails:

    ```text
    STDERR:
    cannot export 'rpool': pool is busy
    ```

    It can be very difficult to nearly impossible to determine why a pool is busy at search an early stage.  All mounts are removed, no datasets are shared yet, no users are within the mounted areas. Without being able to export the pool cleanly during this process, importing the pool will fail upon first reboot.  The following work around imports the pool and allows you to resume the boot process.

    #### Workaround

    * Power down Live CD Environment
    * Remove LiveCD media
    * Power up instance

    The following error message is now expected:

    ```bash
    Importing pool 'rpool' using cachefile. ... Failure 1

    Message: cannot import 'rpool': no such pool available
    Error: 1

    Failed to import pool 'rpool'.
    Manually import the pool and exit.
    ```

    At the `(initramfs)` prompt, type the following:

    ```bash
    zpool import -f bpool
    zpool import -f rpool
    exit
    ```

    The system should now resume booting, if ZFS Encryption is enabled it will prompt for the passphrase.

    * Login as root
    * Reboot the system again
    * Confirm it boots cleanly without the pool import error

    To resume the ansible playbook, you can specify to execute the remaining steps via ansible tags (all at once, or specify one, or a few at a time):

    ```text
    --tags="grub_uefi_multi_disk, create_regular_user, full_install, restart_remote_final, final_cleanup, install_drop_bear"
    ```

2. Multi-disk SWAP using `mdadm` is not mounted as `/dev/md0` and thus no swap space

    ```bash
    $ cat /proc/swaps 
    Filename                             Type       Size    Used    Priority

    $ free -mh | grep Swap
    Swap:         0B          0B       0B
    ```

    If there is anything incorrect with the configuration file `/etc/mdadm/mdadm.conf` the kernel will attempt to assemble the array and mount it as something like `/dev/md127` the swap is configured to be at `/dev/md0` and will not work until this is corrected.

    #### Workaround

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

    This updated the mdadm configuration file, which needs to be added to the kernel initramfs image as follows:

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

* If you have 6 devices of specified type mirror, the `root` pool initially will be constructed as a 2 device mirror. This 1st mirrored vdev pair creates the `root` pool.
* The script will then process all remaining devices, 2 at a time, to create each additional mirrored vdev pair.  
* Each mirrored vdev pair is then attached to the existing `root` pool which expands the pool size by the size of the mirror.

NOTE: internally the script references devices by the `/dev/disk/by-id` device path. However, it by will process devices in the `sda`, `sdb`, `sdc`, `sdd`, etc.. order.  You can experiment with providing an alternate order using Ansible command line parameter `--extra-vars` such as:

```bash
ansible-playbook -i inventory ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdc, sdb, sdd]}'

```

* If your devices are of difference sizes you will want to make sure that each pair such as [`sda` and `sdb`] are close in size to maximize useable disk space. The mirrored vdev will be the size of the smaller device, any space remaining on the larger disk device will remain unused... for now. If you pair a 4TB and 6TB device together, the mirrored vdev will be 4TB and the other 2TB will be unavailable... for now.

* It is technically possible replace the smaller device with a larger one later on, recreate the mirror and expand the vdev to now use the previously unused space.  But again, the mirror can only be as large as the smallest device in the pair.  Doing this is outside the scope of this project.

* Each mirrored vdev pair can be of different sizes.  They do not need to match existing mirror pair sizes.  For example you can have a pair of 4TB and a pair of 6TB devices to create a 10TB root pool.  ZFS will attempt to fill each drive proportionally to maintain a reasonably equal amount of free space on each vdev pair. In this example, a 1MB file would place about 40% on the 4TB pair and 60% on the 6TB pair. This introduces an imbalance and is magnified by the size difference between pairs and the number of pairs.  It is suggested to keep all vdev pairs close in size, but not a requirement.

* If the root pool runs low on space, it is possible to attach additional mirrored vdev pairs to the pool (outside the scope of this project).  Again, be aware of the imbalance this creates.  ZFS will greatly prefer to write to this empty vdev pair and only write a little to the other vdevs attempting to equalize free space.  This imbalance can become a bottleneck.  Unfortunately ZFS has no native way to re-balance how data is distributed across drives.

* If the imbalances described above bothers you, then consider options where all the data is moved somewhere else (external USB or network server). Delete all the data to free up as much space as possible and copy all the data back.  Again, ZFS will always try to balance out available space across the vdevs.

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

NOTE: `mdadm` is used to create mirrored or striped swap partitions.  If you will be replacing a drive then you should mark the device as *failed* before removing it from the system. Failure to do so will likely result in no swap being available.  Marking the device as failed before removal allows the swap device to function even if in a degraded state.

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
