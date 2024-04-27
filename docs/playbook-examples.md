# Additional Playbook Examples

[Back to README.md](../README.md)

The following examples show overriding values from the command-line. Typically it will be easier to define these in the inventory or host_var instead.

The `zfs_on_root.yml` referenced in examples below is a simple yaml file used to call the role, which can look like this:

```yaml
---
- name: ZFS on Root Ubuntu Installation
  hosts: zfs_on_root_install
  become: true
  gather_facts: true

  roles:
    - role: zfs_on_root
```

---

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

* `-vvvv` is VERY verbose (and slower). You can start with just `-v` and add more `v` to increase verbosity if needed.

To do multiple of these at the same time:

```bash
ansible-playbook -i inventory.yml ./zfs_on_root.yml --extra-vars='{disk_devices: [sda, sdb], host_name: testlinux, passphrase: "mySecr3tPa55"}' -l <remote_host_name>
```

If the above is too complicated, no worries.  The script will show you the detected defaults and let you just type values.  It will also show you a summary screen of values for your reference and allow you to abort.

[Back to README.md](../README.md)
