////////////////////////////////////////////////////////
//  GitHub actions variables
////////////////////////////////////////////////////////

variable "name" {
  description = "Name in proxmox UI and GH actions runners"
  type    = string
  default = "ubuntu-noble-runner"
}

variable "runner_org" {
  description = "The org this runner belongs to"
  type    = string
  default = "hivtools"
}

variable "runner_version" {
  type    = string
  default = "2.322.0"
}

variable "runner_token" {
  description = "Token for the the runner"
  type    = string
  sensitive = true
}

////////////////////////////////////////////////////////
//  Proxmox variables
////////////////////////////////////////////////////////

variable "runner_template_id" {
  description = "ID of the proxmox template to clone"
  type    = string
  default = 500
}

variable "runner_ip" {
  description = "Proxmox VM IP"
  type    = string
  default = "192.168.1.202/24"
}

////////////////////////////////////////////////////////
//  VM provision variables
////////////////////////////////////////////////////////

variable "vm_id" {
  type = string
  default = 100
  description = "The ID of the created VM"
}

variable "cores" {
  description = "Number of cores for VM"
  type = number
  default = 4
}

variable "memory" {
  description = "RAM for the VM"
  type = number
  default = 16384
}
