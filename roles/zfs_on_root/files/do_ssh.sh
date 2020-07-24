#!/bin/bash
#
# This is a helper script to reduce the amount of cut & paste 
# needed to get Live CD ready for ansible.
###############################################################

# Create ansible account and a home directory to store SSH keys
sudo useradd -m ansible

# Define remote user password
echo "Enter a temporary password for Ansible account. You will be prompted for this"
echo "password when you attempt to push a generated SSH key to this account."
echo
echo "When installation is complete, the Ansible account will be password disabled,"
echo "Only SSH key based login will be allowed."
echo
sudo passwd ansible
while [ $? -ne 0 ]; do
    sleep 1
    sudo passwd ansible
done

# Add user to sudoers file 
sudo bash -c 'echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99_sudo_include_file'

# Validate sudoers file update
sudo visudo -cf /etc/sudoers.d/99_sudo_include_file
if [[ $? -ne 0 ]]; then 
  #Must return:   /etc/sudoers.d/99_sudo_include_file: parsed OK
  echo ERROR: sudoers validation failed, something went wrong updating sudoers file. 
  echo Unable to continue.
fi

# install SSH Server and Python to allow ansible to connect
sudo apt install --yes openssh-server vim python python-apt

# Disable swap partitions, we don't want them in use when partitions are removed.
swapoff -a
