# GH Actions Proxmox Runners

This repo provides setup for creating GH actions runners on proxmox. It is inspired by [actions/runner-images repo](https://github.com/actions/runner-images) with modification for this to work on proxmox. VM templates are build using packer and then can be run up manually (in the future hopefully via terraform).

## Usage

1. Write a pkrvars file for your proxmox setup with the proxmox connection info. Save it somewhere.
1. Validate the template `packer validate -var-file='./path/to/vars' ./path/to/template`
1. Build the VM template `packer build -var-file='./path/to/vars' ./path/to/template`

This will:
1. Start a VM with the specified iso on your proxmox host.
1. Packer will ssh onto the machine and run provisioner scripts in the VM, including setting up cloud-init
1. Packer will shut down the VM and convert it to a template

To create a new VM from the template
1. Right click in proxmox UI to clone from the template
1. Go to the Cloud-Init settings for the cloned VM and set an IP and gateway e.g. `ip=192.168.1.201/24,gw=8.8.8.8`
1. Boot the VM
