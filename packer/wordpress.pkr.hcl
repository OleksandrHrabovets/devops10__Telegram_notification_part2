packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.0.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.0.0"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "packer-ubuntu-aws"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${ami_prefix} - ${local.timestamp}"
  instance_type = "${instance_type}"
  region        = "${region}"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "${ssh_username}"
}

build {
  name    = "Wordpress AMI with Packer and Ansible"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
    
      "sudo add-apt-repository universe -y",

      "sudo apt-get install -y",
      "sudo apt-get upgrade -y",

      "sudo apt-get install -y python3 python3-pip",
      "sudo apt-get install -y apache2 php php-mysql",

      "sudo systemctl enable apache2",
      "sudo systemctl start apache2"    
    ]
  }

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"
    exttra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3"]
  }
}