# DropBear with Busybox Configuration Settings

[Back to README.md](../README.md)

## Dropbear with Busybox Integrated

This enables a small SSH service at boot time to allow a connection to be made remotely to enter the native ZFS Encryption passphrase. Once entered the system will continue the boot up process.  If you are not using ZFS encryption then there is no need to enable or configure this.

### Enable Dropbear

Dropbear with Busybox can be enabled in the `defaults/main.yml` by setting `enable_dropbear_with_busybox_support` to `true`:

```yaml
###############################################################################
# Dropbear support allows for small SSH service to be included in initram to allow
# for remote connection to enter the ZFS Native Encryption Password.
#
# NOTE: Dropbear's private keys will reside on the unencrypted boot volume. Someone
#       with physical access to the server would be able to discover the private
#       keys.
enable_dropbear_with_busybox_support: true
```

### Configure Dropbear

```yml
apply_dropbear_settings:
  NO_START: "0"
  DROPBEAR_PORT: "2222"
  DROPBEAR_EXTRA_ARGS: "-s -j -k -I 60 -c /bin/unlock"
```

* The `NO_START` option `0` enables Dropbear and `1` disables.
* The `DROPBEAR_EXTRA_ARGS` lock down the environment a bit and prevent an open shell. Only the `unlock` command is allowed and it will be run automatically upon connection.

If you need to troubleshoot why a remote unlock fails, then remove `-c /bin/unlock` from `DROPBEAR_EXTRA_ARGS`and run the playbook to deploy, then restart machine to take effect.

The `/bin/unlock` is a generated script which can be reviewed within the Dropbear shell.  The source of the script is defined within `templates/crypt_unlock.j2`.

### Dropbear RSA Keys

RSA Public keys that are authorized to connect to Dropbear are defined below.  It is questionable how compatible Dropbear is with ECSDA and DSS keys.  RSA Keys are well supported.

```yaml
# Define the full path to public key(s) you want to include in Dropbear
# NOTE: RSA based authentication is advised over ecdsa and dss.
#       To create key:  ssh-keygen -o -a 100 -b 3072 -t rsa -f ~/.ssh/dropbear_rsa  
rsa_public_key_for_dropbear:
  - "/home/rich/.ssh/dropbear_rsa.pub"
```

The path defined above is local on the Ansible controller.  It will be included on the remote server configuration.

### DropBear Restrictions

Additional restrictions are placed on each SSH public key listed above. The restrictions are defined with:

```yaml
# Shell Restrictions placed on each rsa_public_key_for_dropbear entry
dropbear_user_restriction: 'no-port-forwarding,no-agent-forwarding,no-x11-forwarding'
```

Dropbear with Busybox can be deployed and updated independently.  Don't bother forcing it to be installed on a system not using ZFS Native Encryption, there is nothing to prevent the boot up process which would require Dropbear and the unlock script will be of no use.

The `crypt_unlock.j2` has been modified to work with ZFS and will not work with LUKS, etc.

### Manual Execution or Refresh Settings

If at some point in the future you wish to install Dropbear or update its configuration (perhaps add or replace RSA Public Keys) manually use:

```bash
ansible-playbook -i inventory zfs_on_root.yml --extra-vars='{passphrase: "dummypass"}' --tags="install_drop_bear"
```

_NOTE: The correct passphrase for an existing encrypted pool is not actually needed. The passphrase variable just needs to be set for the workflow to be triggered._

### Connecting to Remote Server's Dropbear Prompt

To establish an `SSH` connection to a remote system with Dropbear installed, using your Dropbear specific RSA Key to connect as root:

```bash
$ ssh -i ~/.ssh/dropbear_rsa -p 2222 root@<remote_host_name>

Enter passphrase for 'rpool':
1 / 1 key(s) successfully loaded
ZFS Root Pool Decrypted
Connection to <remote_host_name> closed.
```

The only thing you'll be prompted for is the passphrase to decrypt the root pool. If entered incorrectly you will be given additional attempts.  Once entered correctly the connection is closed and system boot sequence proceeds.  The Dropbear SSH service will not be running once the system has booted.

[Back to README.md](../README.md)
