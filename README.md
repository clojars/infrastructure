# Clojars Server Config

This repo contains the Ansible config to build a Clojars server from scratch. It includes a Vagrantfile for running and testing locally.

# Setting up

Install Virtualbox, Vagrant 1.8, and Ansible 2.0.0. To install Ansible 2 on Homebrew, run `brew install ansible --devel` as it hasn't been officially released yet.

Run `vagrant up` to start up the VM. Before you go any further, run `vagrant snapshot save clean-build`. This will save a snapshot of our VM and allow us to reset our VM state quickly.

To test everything is working, run:

```
ansible all -m ping --inventory local --private-key=.vagrant/machines/default/virtualbox/private_key -u vagrant
```

You should see

```
127.0.0.1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

# Private vars

There is some config for Clojars which is sensitive and cannot be publicly shared in the Github repo. This is placed in `private/vars.yml`. For development purposes, `private/vars.yml.example` is a vars file which looks like the real one but with sensitive information replaced. Run `cp private/vars.yml.example private/vars.yml` to create your private vars file.

# Running playbooks

Run:

```
ansible-playbook -i local --private-key=.vagrant/machines/default/virtualbox/private_key -u vagrant site.yml
```

To restore your vm (I do this every few hours to make sure things haven't drifted too far)

```
vagrant snapshot restore clean-build
```

# Guidelines:

* Follow Ansible [best practices](http://docs.ansible.com/ansible/playbooks_best_practices.html)
* Add an `{{ ansible_managed }}` comment in the header of all templates and files
* Place any private files in `private/`

# Misc

To print manually installed packages:

```
cat /var/log/apt/history.log ) | egrep '^(Start-Date:|Commandline:)' | grep -v aptdaemon | egrep -B1 '^Commandline:'
```

# TODO:

* Decouple dependency on Clojars with building Clojars (build an uberjar to store in S3/GitHub instead?)
* Add a health check to Clojars for automated smoke testing
* Don't call Yeller when doing a staging release
* email setup (inc email SSL)
* cron tasks
* rsync setup
* check all cron jobs run successfully
* SSL


# License

Distributed under the Eclipse Public License. See the file COPYING.
