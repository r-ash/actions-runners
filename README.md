# GH Actions Proxmox Runners

This repo provides setup for creating GH actions runners on proxmox. It is inspired by [actions/runner-images repo](https://github.com/actions/runner-images) with modification for this to work on proxmox. VM templates are build using packer and then can be run up using terraform.

## Usage

### Set env vars

1. Create a user in proxmox with PVEAdmin access
1. Create a token for them

You have to set the following env vars, or provide them via packer & terraform vars
* PKR_VAR_proxmox_api_url - The URL to your proxmox server API e.g. `https://192.168.1.200:8006/api2/json`
* PKR_VAR_proxmox_api_token_id - the API token ID created above
* PKR_VAR_proxmox_api_token_secret - the API token secret created above
* PKR_VAR_winrm_password - password for connecting to windows host via WinRM
* TF_VAR_proxmox_api_url - The URL to your proxmox server API e.g. `https://192.168.1.200:8006/api2/json`
* TF_VAR_proxmox_api_token_id - the API token ID created above
* TF_VAR_proxmox_api_token_secret - the API token secret created above
* TF_VAR_runner_token - token for GH actions for your org or repo, passed to GH actions runner `./config.sh` script
* TF_VAR_winrm_password - password for connecting to windows host via WinRM
* PROXMOX_HOST - The IP without port of the proxmox host e.g. `192.168.1.200`
* PROXMOX_SSH_USER - SSH user to connect to proxmox host
* WINRM_PASSWORD - password for connecting to windows host via WinRM

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

1. Create a github token with `admin:org` permission, save it as an env var called `GITHUB_TOKEN`
1. Run the script `./deploy/start-new.sh --org=hivtools`, this will get a runner registration token for the specified org and then spin up the actions runner from the proxmox VM template using terraform

For configuration of the created proxmox VM see [bpg/proxmox docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)

## Setup

The setup for windows and ubuntu runners is slightly different due to pain points getting them both up and running. The rough lifecycle is as follows:

1. Proxmox template VMs are built using packer, these install dependencies used to run as GitHub actions runners
2. We use terraform to clone the proxmox templates into a running VM on proxmox
3. With Ubuntu we use cloud-init script to add ssh keys and start the GitHub actions service
4. With Windows we use ansible to start the GitHub actions service

## TODO

Still some tidying up of this would be worth doing

1. Add a script for cleanly shutting down existing GitHub actions runners (unregister them from GitHub and remove the VM on proxmox)
2. Rebuild the templates
3. Setup CRON job to automatically shut down existing runners and restart them on some regular basis and a CRON job for rebuild the packer images on some schedule
