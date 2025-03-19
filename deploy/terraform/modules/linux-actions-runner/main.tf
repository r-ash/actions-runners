terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "ash"

  source_raw {
    data = templatefile("${path.module}/user-data.template.yaml", {
        runner_name = "${var.name}"
        runner_version = "${var.runner_version}"
        runner_org = "${var.runner_org}"
        runner_token = "${var.runner_token}"
    })

    file_name = "user-data-cloud-config.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "actions_runner" {
  name      = var.name
  node_name = "ash"
  vm_id = var.vm_id

  clone {
    vm_id = var.runner_template_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.runner_ip
        gateway = "192.168.1.200"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
  }
}

output "vm_ipv4_address" {
  value = proxmox_virtual_environment_vm.actions_runner.ipv4_addresses[1][0]
}
