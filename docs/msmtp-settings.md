# MSMTP Client for SMTP Settings

MSMTP is a client for SMTP used to send system alerts via email as well as used with ZED (ZFS Event Daemon) monitor to provide notifications about ZFS issues (degraded state due to disk failure, etc.)

[Back to README.md](../README.md)

## MSMTP Secrets Configuration

It is suggested you create an email account specifically for SENDING SMTP alerts. I use a GMAIL account for this purpose. If the account is compromised, easy to change password or create a new account.  I would not recommend using your personal email account for SENDING.

Create `vars/secrets/main.yml` (use `vars/secrets/main.yml.exammple` as template for this.)

* Define which email address will be SENDING alerts:

  ```yml
  # Define Email Address system alerts will be FROM
  secret_msmtp_send_from_email: "monitoring@example.com"
  ```

* Define where alerts should be send to (this can be your personal email if you like):

  ```yml
  # Define Default Email Address to send alerts TO
  secret_msmpt_send_to_email: "admin@example.com"
  ```

* Define Email Address and Password to AUTHENTICATE with SMTP server with:

  ```yml
  # Define user name to authenticate to SMTP Server with
  secret_msmtp_auth_user: "monitoring@example.com"

  # Define password for user to authenticate to SMTP Server with
  secret_msmtp_auth_password: "smtp!password"
  ```

If using a GMAIL account, you would create an "App Password" (like a token) within that account and use that password here.  You would NOT use the actual password you as a person would use to log into that account.  The "App Password" can be easily revoked and changed without impacting the actual login credentials for the account.

---

## Review `defaults/main.yml` for MSMTP Configuration

* Enable or Disable Configuration of MSMTP (enabled by default):

  ```yml
  # Enable and Define SMTP Email Alerts for System
  # msmtp is a simple and easy to use SMTP client
  # https://github.com/chriswayg/ansible-msmtp-mailer
  msmtp:
    enabled: true
  ```

* Define the default email domain to use:

  ```yml
  msmtp_domain: "gmail.com"
  ```

* Define the default email account that alerts will be sent to.  By default this value is set to the email account you defined within the secret (see above).

  ```yml
  # Default email alias name to sent alerts to (required)
  msmtp_alias_default: "{{ secret_msmpt_send_to_email | default('not defined within vars/secrets/main.yml') }}"
  ```

* Optionally you can alternate aliases defined for root and cron if needed:

  ```yml
  # Optional Email alias address to redirect "root" emails to
  # msmtp_alias_root: "other.account.for.root@gmail.com"
  # Optional Email alias address to redirect "cron" emails to
  # msmtp_alias_cron: "other.account.for.cron@gmail.com"
  ```

* Multiple email accounts can be defined, and you can specify which email account to use by default. This defaults to using a `gmail` account, but you can change as needed:

  ```yml
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
echo "test message" | sudo mailx -s "Test from $HOSTNAME" <somebody>@gmail.com
```

* Logs: `/var/log/msmtp.log`
* Config: `/etc/msmtprc`

[Back to README.md](../README.md)
