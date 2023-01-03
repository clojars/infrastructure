variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "source_ami_id" {
  type = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "base" {
  access_key                  = "${var.aws_access_key}"
  ami_name                    = "clojars-server ${local.timestamp}"
  associate_public_ip_address = "true"
  instance_type               = "t4g.small"
  region                      = "us-east-2"
  secret_key                  = "${var.aws_secret_key}"
  source_ami                  = "${var.source_ami_id}"
  ssh_username                = "ec2-user"
}

build {
  sources = ["source.amazon-ebs.base"]

  provisioner "shell" {
    script = "scripts/wait_for_cloud_init.sh"
  }

  provisioner "shell" {
    inline = ["echo 'Provisioning Complete.'"]
  }

  provisioner "shell" {
    execute_command   = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    expect_disconnect = "true"
    scripts           = ["scripts/install_base_software.sh"]
    skip_clean        = "true"
    pause_after       = "2m"
  }

  provisioner "shell" {
    env = {
      AWS_ACCESS_KEY_ID     = "${var.aws_access_key}"
      AWS_SECRET_ACCESS_KEY = "${var.aws_secret_key}"
    }

    scripts = ["scripts/setup_ansible_vars.sh"]
  }

  provisioner "ansible-local" {
    playbook_dir  = "../aws-ansible/"
    playbook_file = "../aws-ansible/base.yml"
  }

  provisioner "shell" {
    inline = ["rm /tmp/clojars_vars.yml"]
  }
}
