# Ubuntu Server Noble
# ---
# Packer Template to create an Ubuntu Server (Noble) on Proxmox
packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions
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

variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}

variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}

variable "ssh_username" {
  type    = string
  default = "rob"
}

variable "runner_template_id" {
  type    = string
  default = 500
}

# Resource Definition for the VM Template
source "proxmox-iso" "ubuntu-noble-actions-runner" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    insecure_skip_tls_verify = true
    node = "ash"

    # VM General Settings
    vm_id = var.runner_template_id
    vm_name = "ubuntu-noble-actions-runner-template"
    template_description = "Ubuntu Server Noble (24.04) GH actions runner image"

    # VM OS Settings
    boot_iso {
        type = "scsi"
        #iso_url = "https://releases.ubuntu.com/noble/ubuntu-24.04.1-live-server-amd64.iso"
        iso_file = "local:iso/85d1bf86e5e0ecdd6e91515a63cc10bdab146dca.iso"
        iso_checksum = "e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9"
        unmount = true
        iso_storage_pool = "local"
    }

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "20G"
        format = "raw"
        storage_pool = "local-lvm"
        type = "scsi"
    }

    # VM CPU Settings
    cores = "1"

    # VM Memory Settings
    memory = "4096"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
        "e<wait>",
        "<down><down><down><end>",
        " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<f10>"
    ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "${path.root}/http"

    # PACKER SSH Settings
    ssh_username = "${var.ssh_username}"
    #ssh_agent_auth = true
    ssh_private_key_file = "~/projects/homelab/.ssh/id_ed25519"
    ssh_clear_authorized_keys = true

    # Raise the timeout, when installation takes longer
    ssh_timeout = "55m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-noble-actions-runner"
    sources = [
        "source.proxmox-iso.ubuntu-noble-actions-runner"
    ]

    provisioner "shell" {
        execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
        inline          = ["mkdir ${var.image_folder}", "chmod 777 ${var.image_folder}"]
    }

    provisioner "file" {
        destination = "${var.helper_script_folder}"
        source      = "${path.root}/../scripts/helpers"
    }

    provisioner "shell" {
        environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
        execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
        scripts          = [
            "${path.root}/../scripts/build/configure-apt.sh"
        ]
    }

    provisioner "shell" {
        environment_vars = ["USERNAME=${var.ssh_username}", "DEBIAN_FRONTEND=noninteractive"]
        execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
        scripts          = [
            "${path.root}/../scripts/build/install-docker.sh"
        ]
    }

    provisioner "shell" {
        execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
        pause_before        = "1m0s"
        scripts             = ["${path.root}/../scripts/build/cleanup.sh"]
        start_retry_timeout = "10m"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt-get -y autoremove --purge",
            "sudo apt-get -y clean",
            "sudo apt-get -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "${path.root}/files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}
