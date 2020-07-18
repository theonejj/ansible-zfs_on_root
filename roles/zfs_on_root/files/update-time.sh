# Force refresh of system time, handy with Virtualbox snapshots that boot with incorrect time.
systemctl restart systemd-timesyncd
