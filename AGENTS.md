# Agent Guidance — clojars-infrastructure

This repo manages the infrastructure for Clojars: the Ansible config used to
build the server AMI, the Terraform config for AWS resources, and the scripts
used to cut and deploy releases.

## Hard rules

- **Never run `terraform apply`.** Plans, formatting, and validation are fine;
  applying changes to production must be done by a human. The same goes for
  any command that mutates real infrastructure (e.g. `terraform destroy`,
  `terraform state rm/mv`, `aws ... delete-*`, `aws ssm put-parameter`,
  `scripts/cycle-instance.sh`, `scripts/deploy.sh`, `scripts/build_ami.sh`,
  `scripts/upload-release.sh`). Propose the command and let the human run it.
- **Don't edit DNS in the DNSimple dashboard.** DNS for `clojars.org` and
  `clojars.net` is managed in `terraform/dns.tf` — change it there.
- **Don't touch `.envrc`.** It contains real AWS keys and secrets. Don't
  cat/read it, copy it, paste it into responses, or commit changes to it.
  If credentials are needed for a task, ask the human to run the command.
- **Treat SSM `/clojars/production/*` values as secrets.** Don't fetch or
  print encrypted parameter values; refer to them by name.

## Layout

- `terraform/` — AWS resources (ASG, LB, RDS, S3, SQS, IAM, VPC, CloudWatch)
  and DNSimple records. State lives in S3 (`clojars-tf-state`) with S3-native
  locking (`use_lockfile`). Region: `us-east-2`.
- `ami/` — Packer config (`packer.json.pkr.hcl`) for building the Clojars AMI.
- `aws-ansible/` — Ansible roles/playbooks applied during AMI build.
- `scripts/` — Release, deploy, and instance-management helpers.
- `bin/` — Pinned wrappers for `terraform` and `packer` (downloaded into
  `bin/.cache/`). Prefer these over a system install so versions match CI.
- `README.md` — Authoritative human-facing docs for setup, deploy, AMI build.

## Working in this repo

- Read `README.md` for the deploy/AMI flow before suggesting changes there.
- Terraform changes: edit the `.tf` file, run `terraform fmt` and
  `terraform validate` in `terraform/`, and optionally `terraform plan` to
  show the human the diff. Stop there.
- Sensitive config (DB password, OAuth secrets, SES creds, etc.) is stored in
  SSM Parameter Store under `/clojars/production/*`, not in this repo.
- Ansible templates should include an `{{ ansible_managed }}` header comment.

## Local context

- Env vars (`AWS_*`, `DNSIMPLE_*`, `CLOJARS_SSH_KEY_FILE`, `TF_VAR_*`) are
  loaded via `direnv` from `.envrc`. Assume they're already set in the shell;
  don't try to set or echo them.
- The `bin/` wrappers require `direnv` (or a manual `PATH` addition) to be
  picked up ahead of system binaries.
