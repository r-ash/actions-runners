terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "ssh_username" {
  description = "Username used to ssh into the proxmox host as"
  type    = string
  default = "root"
}

variable "runner_template_id" {
  description = "Proxmox VM ID for the template to clone from"
  type    = string
  default = 500
}

variable "runner_name" {
  description = "Name in proxmox UI and GH actions runners"
  type    = string
  default = "ubuntu-noble-runner"
}

variable "runner_org" {
  description = "The org this runner belongs to"
  type    = string
  default = "hivtools"
}

variable "runner_token" {
  description = "Token for the the runner"
  type    = string
  sensitive = true
}

variable "runner_version" {
  type    = string
  default = "2.322.0"
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true
  ssh {
    agent    = true
    username = var.ssh_username
  }
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "ash"

  source_raw {
    data = templatefile("${path.module}/user-data.template.yaml", {
        runner_name = "${var.runner_name}"
        runner_version = "${var.runner_version}"
        runner_org = "${var.runner_org}"
        runner_token = "${var.runner_token}"
    })

    file_name = "user-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "actions_runner" {
  name      = var.runner_name
  node_name = "ash"

  clone {
    vm_id = var.runner_template_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 16384
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.202/24"
        gateway = "192.168.1.200"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }
}

output "vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.actions_runner.ipv4_addresses[1][0]
}
