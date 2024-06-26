# Clojars Server Config

This repo contains the Ansible config for building the AMI for the
Clojars server, the terraform for managing the Clojars
infrastructure on AWS, and scripts to deploy a Clojars release.

# System Diagram

![System Diagram](./system_diagram.png)

# Setup

## AWS Credentials

You will also need a AWS access key, exported as `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`. These vars need to be set to run
terraform, build an AMI, or deploy. You will also need to set
`CLOJARS_SSH_KEY_FILE` to the path to the private key used by the
server if you want to deploy or ssh in to the server.

### clojars-env script

One way to have all those vars set is to create a wrapper script that
sets them (called `clojars-env` in this example):

```sh
#!/bin/bash

export AWS_ACCESS_KEY_ID=ASDFASDFASDF
export AWS_SECRET_ACCESS_KEY=3ASD3434AA
export AWS_REGION=us-east-2
export CLOJARS_SSH_KEY_FILE=~/.ssh/clojars-server.pem

exec $@
```

Then execute commands with:

`clojars-env terraform apply` 

### direnv

Alternatively, you can use [direnv](https://direnv.net/) to set 
the environment variables.

Create a `.envrc` file at the root of the repo:

```
export AWS_ACCESS_KEY_ID=ASDFASDFASDF
export AWS_SECRET_ACCESS_KEY=3ASD3434AA
export AWS_REGION=us-east-2
export CLOJARS_SSH_KEY_FILE=~/.ssh/clojars-server.pem
PATH_add bin
```

Install direnv and run `direnv allow` in the repo directory. Now, 
everytime you cd into the repo directory, the environment variables 
will be set.

## Terraform

We have a wrapper around terraform (`bin/terraform`) that will download 
and install the correct version (cached in `bin/.cache/`).

### Initialization

The terraform state is stored in S3 and uses a DynamoDB table to lock that state
when it is being altered. On first run, you will need to initialize terraform
with (this assumes you have set up `direnv` as above to use `bin/terraform`):

```sh
cd terraform
terraform init
```
### Applying the configuration

```sh
cd terraform
terraform apply
```

## Packer

We have a wrapper around packer (`bin/packer`) that will download and install
the correct version (cached in `bin/.cache/`).

## Sensitive Configuration Data

We store sensitive configuration data in [AWS SSM parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html).

the following parameters exist currently (ones marked with a 🔒 are encrypted):

- `/clojars/production/ami_id`
- `/clojars/production/cdn_token` 🔒
- `/clojars/production/db_host`
- `/clojars/production/db_password` 🔒
- `/clojars/production/db_user` 🔒
- `/clojars/production/github_oauth_client_id` 🔒
- `/clojars/production/github_oauth_client_secret` 🔒
- `/clojars/production/gitlab_oauth_client_id` 🔒
- `/clojars/production/gitlab_oauth_client_secret` 🔒
- `/clojars/production/sentry_dsn` 🔒
- `/clojars/production/sentry_token` 🔒
- `/clojars/production/ses_password` 🔒
- `/clojars/production/ses_username` 🔒
- `/clojars/production/ssh_keys`

You can retrieve the value of a parameter with:

``` sh
aws ssm get-parameter --name <name> --query "Parameter.Value" --with-decryption
```


# Listing running instances

There is a convenience script to list all EC2 instances:

`scripts/list-instances.sh`

# Deployment

To deploy a new release of Clojars, you have a few options:

- You can build and upload a new release to S3, then deploy a new AMI
  that will pick up the release (see below)
- You can build and upload a new release to S3, then request that a
  running server switch to that release
- You can also switch back to an older release

To build and upload a new release, first tag the release (in `clojars-web`):

`make tag-release`

This will create and push a tag of the form `<date>.<commit-count>` (example: `2023-08-20.1982`).

Then run:

`scripts/upload-release.sh <version-tag>`

This will check to see if an artifact for that tag already exists in
the deployment bucket. If not, it will pull down the tag from GitHub,
build an uberjar, then upload a zip containing that uberjar and the
`scripts/` dir from `clojars-web` to the deployment bucket. 

It then writes a `current-release.txt` containing the tag to the
deployment bucket.

To deploy a release to a running server, run:

`scripts/deploy.sh <server-ip> <version-tag>`

This will first call `scripts/upload-release.sh`, then ssh to the
server and run the [deploy-clojars
script](./aws-ansible/roles/clojars/files/bing-scripts/deploy-clojars). This
script will pull down the version specified by `current-release.txt`
and deploy it. This script is the same script that runs when the
Clojars AMI boots.

# Building an AMI

We build a custom AMI using packer, and apply changes to the AMI with ansible.
To run packer, call (this assumes you have set up `direnv` as above to use
`bin/packer`):

`scripts/build_ami.sh`

This will take a few minutes, but will produce a new AMI. The ID of the new AMI
will be written to the `/clojars/production/ami_id` SSM parameter, which is read by `terraform/asg.tf`.

# Deploying a new AMI

1. Run `terraform apply` in `terraform/`. This will pick up and apply the new
   AMI ID from the `/clojars/production/ami_id` SSM parameter.
2. Changes to a launch configuration don't affect *running* instances, so we will
   have to force a new instance. You can do so by running 
   `scripts/cycle-instance.sh`.
   

## Ansible Guidelines

* Follow Ansible [best
  practices](http://docs.ansible.com/ansible/playbooks_best_practices.html)
* Add an `{{ ansible_managed }}` comment in the header of all templates and files


Distributed under the MIT License. See the file COPYING.
