# DropBear Configuration Settings

[Back to README.md](../README.md)

## Dropbear  Integrated

This enables a small SSH service at boot time to allow a connection to be made remotely to enter the native ZFS Encryption passphrase. Once entered the system will continue the boot up process.  If you are not using ZFS encryption then there is no need to enable or configure this.

### Enable Dropbear

Dropbear can be enabled in the `defaults/main.yml` by setting `enable_dropbear_support` to `true`:

```yaml
enable_dropbear_support: true
apply_dropbear_settings:
  # Automatic (dhcp) or static IP assignment for zfsbootmenu remote access
  # "dhcp", "dhcp,dhcp6", "dhcp6", or "static"
  remoteaccess_ip_config: "dhcp"
  # Remote access static IP address to connect to ZFSBootMenu
  # Only used with "static", not used for dhcp or dhcp6 automatic IP configuration
  remoteaccess_ip: "192.168.0.222"
  # Remote access subnet mask
  # Only used with "static", not used for dhcp or dhcp6 automatic IP configuration
  remoteaccess_netmask: "255.255.255.0"
```

* The `remoteaccess_ip_config` selects if you want Dropbear to request a DHCP address or you wish to supply a static IP address
  * If a static address is selected, then set `remoteaccess_ip` and `remoteaccess_netmask` to the appropriate values

### Dropbear RSA Keys

ECSDA or RSA public keys are authorized to connect to Dropbear are defined below.

```yaml
  # Define the full path to public key(s) you want to include in Dropbear
  # Allow dracut / dropbear use main user authorized_keys for access
  # Note that login to dropbear is "root" regardless of which authorized_keys is used
  public_key_for_dropbear: "/home/{{ regular_user_accounts[0].user_id }}/.ssh/authorized_keys"```
```

The default value shown above, states that any authorized key defined by the first non-root user as specified in [Define the Non-Root Account(s)](../README.md#define-the-non-root-accounts) will be allowed to connect to Dropbear.

### Manual Execution or Refresh Settings

If at some point in the future you wish to install Dropbear or update its configuration manually use:

```bash
ansible-playbook zfs_on_root.yml -l hostname --tags="install_dropbear"
```

### Connecting to Remote Server's Dropbear Prompt

To establish an `ssh` connection to a remote system with Dropbear installed, use any key defined in your authorized_keys on the remote host.  To copy one of your keys to the remote system:

```shell
$ ssh-copy-id -i ~/.ssh/dropbear_ed25519 <user_name>@<remote_host_name>

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/<user_name>/.ssh/dropbear_ed25519.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
<user_name>@<remote_host_name>'s password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '<user_name>@<remote_host_name>'"
and check to make sure that only the key(s) you wanted were added.
```

* You should now be able to perform a standard ssh login to the remote system with this key, it will not prompt for a password and you should get the banner and user command prompt:

```shell
$ ssh -i ~/.ssh/dropbear_ed25519 <remote_host_name>

Welcome to Ubuntu 22.04.1 LTS (GNU/Linux 5.15.0-53-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The list of available updates is more than a week old.
To check for new updates run: sudo apt update

<user_name>@<remote_host_name>:~$
```

Upon rebooting the remote system, you can connect to Dropbear as follows. This example uses a ECSDA key to connect as root (no matter what key you connect with, you must always connect as the root user).

```bash
$ ssh -i ~/.ssh/dropbear_ed25519 -p 222 root@<remote_host_name>

Welcome to the ZFSBootMenu initramfs shell. Enter "zbm" to start ZFSBootMenu.
zfsbootmenu ~ > 
```

* Enter `zbm` to access the ZFSBootMenu:

You will then be prompted to enter the ZFS encryption passphrase:

```shell
Enter passphrase for '<remote_host_name>/ROOT':
```

* Enter your passphrase to unlock the ZFS pool.
* If entered incorrectly you will be given additional attempts.

You will then be presented with the ZFSBootMenu to select what to boot or rollback the system to a previous ZFS snapshot, etc.  Once a selection is made connection is closed and system boot sequence proceeds.  The Dropbear SSH service will not be running once the system has booted.

* NOTE: SSH clients have started to drop support for RSA keys.  The `-o PubKeyAcceptedKeyTypes=+ssh-rsa` is required on such clients otherwise you will get an access denied trying to connect.

[Back to README.md](../README.md)
