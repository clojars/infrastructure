#!/bin/bash

ip=$1

echo "$ip" > /tmp/clojars-ansible-inventory

ansible-playbook \
  -e host=$ip \
  --inventory /tmp/clojars-ansible-inventory \
  --vault-password-file ~/.vault_pass.txt \
  base.yml
