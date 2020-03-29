## Terraform config for setting up Clojars on AWS

### Prerequisites

You will need terraform installed:
https://www.terraform.io/downloads.html (currently v0.12.19).

You will also need a AWS access key, exported as `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`.

### Initialization

The terraform state is stored in S3 and uses a DynamoDB table to lock
that state when it is being altered. On first run, you will need to
initialize terraform with:

```sh
terraform init
```

### Applying the configuration

```sh
terraform apply
```

