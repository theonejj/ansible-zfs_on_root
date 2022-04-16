# Helper Scripts

[Back to README.md](../README.md)

## do_ssh.sh

Once the Ubuntu Live CD is booted on the target system, there are a number of steps you need to perform to allow ansible to connect to it over the network such as update packages, create an ansible user account, define a password, grant the ansible account `sudo` privileges, install SSH server, etc.  The helper script named `do_ssh.sh` completes all this work for you.  Simply use `wget` to fetch the file, use `chmod +x do_ssh.sh` to make it executable and run it `./so_ssh.sh` that's all.

```bash
wget https://raw.githubusercontent.com/reefland/ansible-zfs_on_root/master/files/do_ssh.sh

chmod +x do_ssh.sh

./do_ssh.sh
```

### If "do_ssh.sh" Helper Script is not Available

These are the manual commands performed by the helper script.  If it is not available, these steps do the same.  Enter these at the shell prompt on the LiveCD environment.

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

[Back to README.md](../README.md)
