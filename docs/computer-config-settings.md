# Computer Configuration Settings

[Back to README.md](../README.md)

## UEFI or Legacy BIOS

Does not matter if UEFI or Legacy BIOS is used. When available UEFI will be used, if not available it will automatically fallback to BIOS.  You should be easily able to move between these options.

## Default Domain Name

The default domain name to assign to computers can be defined here.  This value can be overridden per host in the inventory file as needed.

```yaml
# Default domain hosts will use if not defined in inventory file
domain_name: "localdomain"
```

## rEFInd Boot Menu Timeout

By default rEFInd boot menu will wait 20 seconds for you take make a section.  This is a bit on the long side for most configurations.  This value will override this configuration:

```yaml
# rEFInd Boot Menu Timeout by default is 20 seconds.
refind_boot_menu_timeout: "10"
```

## CLI or Full Desktop

Select if Full Graphical Desktop or Command Line Server only.

```yaml
# For Full GUI Desktop installation (set to false) or command-line only server environment (set to true)
command_line_only: true
```

## Enable Ubuntu LTS Hardware Enablement Kernel

This provides newer kernels than the default LTS kernel.

```yaml
# The Ubuntu LTS enablement (also called HWE or Hardware Enablement) stacks
# provide newer kernel and X support for existing Ubuntu LTS releases.
enable_ubuntu_lts_hwe: false
```

## Define Locale and Timezone

Set your locale and timezone information.

```yaml
# Define the local pre-fix to enable in /etc/locale.gen
locale_prefix: "en_US"

# Define the timezone to be placed in /etc/timezone
timezone_value: "America/New_York"
```

## Disable IPv6 Networking

By default IPv6 networking will be disabled.  If you have a need for it, you can set `ipv6.disable: false`. You can also customize which settings are applied and how they are applied as well.

```yaml
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

### Disable Partprobe

`partprobe` is used to let the kernel know that partition tables have been updated.  It is required when partitions are created or deleted. It should always be enabled, but can be disabled if required.

```yaml
# "Partprobe" is used to let the kernel know that partition tables have changed.
# Sometimes it gets in the way with weird messaged such as:
# "The driver descriptor says the physical block size is 2048 bytes, but Linux
# says it is 512 bytes."
disable_partprobe: false
```

## Additional Installed Packages

These are the packages to be be applied to the towards the end of the build process to be included as part of the base system installation.

```yaml
# Define additional packages to install once the build has completed.
additional_install_packages:
  - man
  - udisks2
  - pciutils
  - net-tools
  - ethtool
  - fonts-ubuntu-console
  - htop
  - pollinate
  - fwupd
  - needrestart
  - unattended-upgrades
  - lz4
```

## MSMTP SMTP Email Client

`msmtp` is a simple and easy to use SMTP client. This is intended for system SMTP notifications by the `root` user.  These variables are passed to an Ansible Galaxy role which can be reviewed at <https://github.com/chriswayg/ansible-msmtp-mailer>.

Multiple email accounts can be defined, along with a default account to use.  Below shows a `gmail.com` configuration.  

* Values for `from`, `user` and `password` are defined within `vars/secrets/main.yml`.

```yaml
msmtp:
  enabled: true
  msmtp_domain: "gmail.com"
  # Default email alias name to sent alerts to (required)
  msmtp_alias_default: "{{ secret_msmpt_send_to_email | default('not defined within vars/secrets/main.yml') }}"
  # Optional Email alias address to redirect "root" emails to
  # msmtp_alias_root: "other.account.for.root@gmail.com"
  # Optional Email alias address to redirect "cron" emails to
  # msmtp_alias_cron: "other.account.for.cron@gmail.com"

  msmtp_default_account: "gmail"
  accounts:
    - account: "gmail"
      host: "smtp.gmail.com"
      port: "587"
      auth: "on"
      from: "{{ secret_msmtp_send_from_email | default('not defined within vars/secrets/main.yml') }}"
      user: "{{ secret_msmtp_auth_user | default('not defined within vars/secrets/main.yml') }}"
      password: "{{ secret_msmtp_auth_password | default('not defined within vars/secrets/main.yml') }}"
```

To send a test email once configured:

```shell
echo test message | sudo mailx -s "Test from $HOSTNAME" <somebody>@gmail.com
```

* Logs: `/var/log/msmtp.log`
* Config: `/etc/msmtprc`

[Back to README.md](../README.md)
