# GH Actions Proxmox Runners

This repo provides setup for creating GH actions runners on proxmox. It is inspired by [actions/runner-images repo](https://github.com/actions/runner-images) with modification for this to work on proxmox. VM templates are build using packer and then can be run up vis terraform.

## Usage

### Set env vars

1. Create a user in proxmox with PVEAdmin access
1. Create a token for them

You have to set the following env vars, or provide them via packer & terraform vars
* PKR_VAR_proxmox_api_url - The URL to your proxmox server API e.g. `https://192.168.1.200:8006/api2/json`
* PKR_VAR_proxmox_api_token_id - the API token ID created above
* PKR_VAR_proxmox_api_token_secret - the API token secret created above
* TF_VAR_proxmox_api_url - The URL to your proxmox server API e.g. `https://192.168.1.200:8006/api2/json`
* TF_VAR_proxmox_api_token_id - the API token ID created above
* TF_VAR_proxmox_api_token_secret - the API token secret created above
* TF_VAR_runner_token - token for GH actions for your org or repo, passed to GH actions runner `./config.sh` script

You can optionally set
* TF_VAR_runner_org - to set the org the GH actions runner should belong to

### Build template with packer

1. Write a pkrvars file for your proxmox setup with the proxmox connection info. Save it somewhere.
1. Validate the template `packer validate ./path/to/template`
1. Build the VM template `packer build ./path/to/template`

This will:
1. Start a VM with the specified iso on your proxmox host.
1. Packer will ssh onto the machine and run provisioner scripts in the VM, including setting up cloud-init
1. Packer will shut down the VM and convert it to a template

To create a new VM from the template
1. Right click in proxmox UI to clone from the template
1. Go to the Cloud-Init settings for the cloned VM and set an IP and gateway e.g. `ip=192.168.1.201/24,gw=192.168.1.200`
1. Boot the VM

### Deploying from template

1. From the `deploy/ubuntu` directory run `terraform apply`
1. Depending on how many runners you are starting up you might need to set the `runner_name` variable and the the fixed IP address

For configuration of the created proxmox VM see [bpg/proxmox docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)
