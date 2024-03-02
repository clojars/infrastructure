#!/usr/bin/env bash

set -euo pipefail

# Update package index.  Yum check-update returns 100 if there are packages
# to update.
set +e
dnf check-update
if [ $? -eq 1 ]
then
    echo "dnf check-update failed."
    exit 1
fi
set -e

# Install core packages
dnf install --assumeyes \
    wget \
    unzip \
    libffi-devel \
    glibc \
    gcc \
    python3-pip

# Install Ansible
pip install ansible==8.7.0 lxml==5.1.0

# Reboot
echo "Rebooting."
nohup reboot < /dev/null > /dev/null 2>&1 &
exit 0
