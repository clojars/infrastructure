This directory is the ansible configuration for running Clojars on
AWS. 

The eventual goal is to run this to build an AMI, but it is currently
used against a running instance.

Eventually there will be instructions here for creating a new instance
and replacing the currently running one.

## Listing instances

You can list running aws instances with:

```sh
list-instances.sh
```

## Deployment

To deploy to an already-ansibled instance, use the `deploy.sh` script:

```sh
deploy.sh <instance-public-ip> <clojars-version>
```

This will checkout, build, and deploy the given clojars version on the
given instance. 

Note: this needs to be able to provide the correct ssh cert for that
instance, so `~/.ssh/config` needs to be appropriately configured.

