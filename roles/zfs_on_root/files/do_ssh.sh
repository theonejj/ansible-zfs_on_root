#!/bin/bash
#
# This is a helper script to reduce the amount of cut & paste 
# needed to get Live CD ready for ansible.
###############################################################

ANSIBLE_USER=ansible

sudo apt-add-repository universe && sudo apt update

# Create ansible account and a home directory to store SSH keys
echo
echo "-----------------------------------------------------------------------------"
sudo useradd -m $ANSIBLE_USER
if [[ $? -ne 0 ]]; then 
  echo ERROR: was unable to add $ANSIBLE_USER user, already created?
else
  echo Created user: $ANSIBLE_USER
fi

# Define remote user password
echo
echo "-----------------------------------------------------------------------------"
echo "Enter a temporary password for Ansible account. You will be prompted for this"
echo "password when you attempt to push a generated SSH key to this account."
echo
echo "When installation is complete, the Ansible account will be password disabled,"
echo "Only SSH key based login will be allowed."
echo
sudo passwd $ANSIBLE_USER
while [ $? -ne 0 ]; do
    echo
    sleep 1
    sudo passwd $ANSIBLE_USER
done

# Add user to sudoers file 
sudo bash -c "echo \"$ANSIBLE_USER ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/99_sudo_include_file"

# Validate sudoers file update
sudo visudo -cf /etc/sudoers.d/99_sudo_include_file
if [[ $? -ne 0 ]]; then 
  #Must return:   /etc/sudoers.d/99_sudo_include_file: parsed OK
  echo
  echo "ERROR: sudoers validation failed, something went wrong updating sudoers file."
  echo "Unable to continue."
  exit
fi

# install SSH Server and Python to allow ansible to connect
sudo apt install --yes openssh-server vim python python-apt
if [[ $? -ne 0 ]]; then
  echo
  echo "ERROR: installing required packages failed."
fi

# Disable swap partitions, we don't want them in use when partitions are removed.
swapoff -a

# Done
echo
echo "-----------------------------------------------------------------------------"
echo "Completed.  Now push your ansible ssh key to this instance from the Ansible"
echo "Control node."
