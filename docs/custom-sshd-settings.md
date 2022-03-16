# Customized SSHD Settings

[Back to README.md](../README.md)

## Enable SSHD Configuration

The `update_sshd_settings` within `defaults/main.yml` will  enable (true) or disable (false) updating SSH entries.

## SSHD Configuration Settings

Some of the basic, more common SSHD Configuration settings can be updated.  Ansible does not have a specific module for updating `sshd_config`.  The grep rules in the helper task handle most of the `yes`, `no`, `numerical` such as 10, 22, or 2m.  More complex matches like IP addresses and directory paths are not supported.

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

Values can be changed and new key pair entries can be added. When ready to deployed changes (and `sshd` service will be restarted) using the following:

```bash
ansible-playbook -i inventory zfs_on_root.yml --tags="update_sshd_settings"
```

[Back to README.md](../README.md)
