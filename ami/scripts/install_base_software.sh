#!/usr/bin/env bash

set -euo pipefail

# Update package index.  Yum check-update returns 100 if there are packages
# to update.
set +e
yum check-update
if [ $? -eq 1 ]
then
    echo "yum check-update failed."
    exit 1
fi
set -e

# Install core packages
yum install --assumeyes \
    wget \
    unzip \
    libffi-devel \
    glibc \
    gcc

# Install Ansible
curl -O https://bootstrap.pypa.io/2.7/get-pip.py
python get-pip.py
pip install ansible==2.9.4

# Reboot
echo "Rebooting."
nohup reboot < /dev/null > /dev/null 2>&1 &
exit 0
