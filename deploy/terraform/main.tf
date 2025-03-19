variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "winrm_password" {
  type = string
  sensitive = true
}

variable "ssh_username" {
  description = "Username used to ssh into the proxmox host as"
  type    = string
  default = "root"
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

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.71.0"
    }
  }
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

variable "vm_configs" {
  type = list(object({
    name = string
    os    = string
    ip    = optional(string)
    vm_id = number
  }))
  // Note IP for linux is set via cloud-init but it was a battle to get
  // cloudbase-init to work with windows for this, so instead we get the windows
  // IP after creating it. TODO: set a static IP here
  default = [
    { name = "ubuntu-noble-runner-1", os = "linux", ip = "192.168.1.202/24", vm_id = 100},
    { name = "windows-runner-1", os = "windows", vm_id = 200}
  ]
}

locals {
  linux_runners  = { for vm in var.vm_configs : vm.name => vm if vm.os == "linux" }
  windows_runners = { for vm in var.vm_configs : vm.name => vm if vm.os == "windows" }
}

module "linux_runner" {
  source = "./modules/linux-actions-runner"

  for_each = local.linux_runners

  name         = each.value.name
  runner_ip    = each.value.ip
  runner_token = var.runner_token
  runner_org   = var.runner_org
  vm_id        = each.value.vm_id
}

module "windows_runner" {
  source = "./modules/windows-actions-runner"

  for_each = local.windows_runners

  name           = each.value.name
  runner_token   = var.runner_token
  runner_org     = var.runner_org
  winrm_password = var.winrm_password
  vm_id          = each.value.vm_id
}

output "windows_vm_ids" {
  value = [for vm in var.vm_configs : vm.vm_id if vm.os == "windows"]
}
