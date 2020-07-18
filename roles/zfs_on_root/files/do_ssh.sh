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
sudo passwd ansible

# Add user to sudoers file 
sudo bash -c 'echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/99_sudo_include_file'

# Validate sudoers file update
sudo visudo -cf /etc/sudoers.d/99_sudo_include_file

#Must return:   /etc/sudoers.d/99_sudo_include_file: parsed OK

# install SSH Server and Python to allow ansible to connect
sudo apt install --yes openssh-server vim python python-apt
