## Terraform config for setting up Clojars on AWS

### Prerequisites

You will need terraform installed:
https://www.terraform.io/downloads.html (currently v0.12.19).

You will also need a AWS access key, exported as `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`.

TODO: set up remote state

### Applying a configuration

```
# as an example
cd s3/
terraform apply
```

