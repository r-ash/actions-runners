terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
}

resource "proxmox_virtual_environment_vm" "actions_runner" {
  name      = var.name
  node_name = "ash"
  vm_id     = var.vm_id

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

  disk {
    size         = 50
    file_format  = "raw"
    datastore_id = "local-lvm"
    interface    = "virtio0"
  }
}

