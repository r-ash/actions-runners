# Ubuntu Server Noble
# ---
# Packer Template to create an Ubuntu Server (Noble) on Proxmox
packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
    windows-update = {
      version = "0.16.8"
      source = "github.com/rgl/windows-update"
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

# variable "helper_script_folder" {
#   type    = string
#   default = "/imagegeneration/helpers"
# }

variable "runner_template_id" {
  type    = string
  default = 501
}

variable "winrm_username" {
  type = string
  description = "WinRM user"
  default = "Administrator"
}

variable "winrm_password" {
  type = string
  sensitive = true
  description = "WinRM password"
}

variable "cdrom_drive" {
  type = string
  description = "CD-ROM Driveletter for extra iso"
  default = "D:"
}

variable "helper_script_folder" {
  type    = string
  default = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
}

variable "image_folder" {
  type    = string
  default = "C:\\image"
}

variable "temp_dir" {
  type    = string
  default = "C:\\temp"
}

# Resource Definition for the VM Template
source "proxmox-iso" "windows-actions-runner" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    insecure_skip_tls_verify = true
    node = "ash"

    # BIOS - UEFI
    bios = "ovmf"

    # Machine type
    # Q35 less resource overhead and newer chipset
    machine = "q35"

    efi_config {
        efi_storage_pool = "local-lvm"
        pre_enrolled_keys = true
        efi_type = "4m"
    }

    # VM General Settings
    vm_id = var.runner_template_id
    vm_name = "windows-actions-runner-template"
    template_description = "Windows GH actions runner template"

    # VM OS Settings
    boot_iso {
        #iso_url = "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"
        iso_file = "local:iso/SERVER_EVAL_x64FRE_en-us.iso"
        iso_checksum = "none"
        #iso_checksum = "3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"
        unmount = true
        iso_storage_pool = "local"
    }

    additional_iso_files {
        #cd_files = ["${path.root}/../drivers/*","${path.root}/../software/virtio-win-guest-tools.exe"]
        cd_files = ["${path.root}/../scripts/build/bootstrap.ps1"]
        cd_content = {
            "autounattend.xml" = templatefile("autounattend.pkrtpl", {username = var.winrm_username, password = var.winrm_password, cdrom_drive = var.cdrom_drive})
        }
        cd_label = "cidata"
        iso_storage_pool = "local"
        iso_checksum = "none"
        type = "ide"
        index = 3
        unmount = true
    }

    ## Index 0 gives disk id D:
    additional_iso_files {
        iso_file = "local:iso/virtio-win.iso"
        iso_checksum = "none"
        unmount = true
        iso_storage_pool = "local"
        type = "sata"
        index = 0
    }

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-single"

    disks {
        disk_size = "40G"
        format = "raw"
        storage_pool = "local-lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "1"

    # VM Memory Settings
    memory = "4096"

    os = "win11"
    qemu_agent = true

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    cloud_init = false

    # Boot Commands
    boot_command = [
        "<enter>"
    ]
    boot = "order=ide0;ide3;ide2"
    boot_wait = "7s"

    # WinRM
    communicator          = "winrm"
    winrm_username        = var.winrm_username
    winrm_password        = var.winrm_password
    winrm_timeout         = "12h"
    winrm_port            = "5985"
    winrm_use_ssl         = false
    winrm_insecure        = true
}

# Build Definition to create the VM Template
build {

    name = "windows-actions-runner"
    sources = [
        "source.proxmox-iso.windows-actions-runner"
    ]

    provisioner "windows-restart" {
    }

    provisioner "powershell" {
        inline = [
            "New-Item -Path ${var.image_folder} -ItemType Directory -Force",
            "New-Item -Path ${var.temp_dir} -ItemType Directory -Force"
        ]
    }

    provisioner "file" {
        destination = "${var.image_folder}\\"
        sources     = [
            "${path.root}/../scripts",
        ]
    }

    provisioner "powershell" {
        inline = [
            "Move-Item '${var.image_folder}\\scripts\\helpers' '${var.helper_script_folder}\\ImageHelpers'",
            "Remove-Item -Recurse '${var.image_folder}\\scripts'"
        ]
    }

    # provisioner "powershell" {
    #     script = "${path.root}/../scripts/build/Install-CloudBase.ps1"
    # }

    provisioner "powershell" {
        environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
        scripts = [
            "${path.root}/../scripts/build/Configure-WindowsDefender.ps1",
            "${path.root}/../scripts/build/Install-WindowsFeatures.ps1",
            "${path.root}/../scripts/build/Install-Chocolatey.ps1",
            "${path.root}/../scripts/build/Configure-BaseImage.ps1"
        ]
    }

    provisioner "windows-restart" {
        check_registry = true
        restart_timeout = "10m"
    }

    provisioner "powershell" {
        environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}", "DOCKER_VERSION=26.1.3"]
        scripts = [
            "${path.root}/../scripts/build/Install-Docker.ps1",
            "${path.root}/../scripts/build/Install-Docker-ce.ps1",
            "${path.root}/../scripts/build/Install-DockerWinCred.ps1",
            "${path.root}/../scripts/build/Install-PowershellCore.ps1",
            "${path.root}/../scripts/build/Install-ChocolateyPackages.ps1"
        ]
    }

    provisioner "windows-restart" {
        restart_timeout = "10m"
    }

    provisioner "powershell" {
        environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}", "DOCKER_VERSION=26.1.3"]
        scripts = [
            "${path.root}/../scripts/build/Install-ActionsCache.ps1",
            "${path.root}/../scripts/build/Install-Runner.ps1",
            "${path.root}/../scripts/build/Install-Spectrum.ps1",
            "${path.root}/../scripts/build/Install-Git.ps1"
        ]
    }

    provisioner "windows-restart" {
        restart_timeout = "10m"
    }

    provisioner "windows-update" {
        search_criteria = "IsInstalled=0"
        filters = [
            "exclude:$_.Title -like '*Preview*'",
            "include:$true",
        ]
        update_limit = 25
    }
}
