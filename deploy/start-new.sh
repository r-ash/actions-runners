#!/bin/bash
################################################################################
##  File:  start.sh
##  Desc:  Get a registration token for the org and then deploy a new runner with it
################################################################################

set -e

# Ensure GITHUB_TOKEN is set
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Error: GITHUB_TOKEN environment variable is not set." >&2
  exit 1
fi

# Ensure WINRM_PASSWORD is set
if [[ -z "$WINRM_PASSWORD" ]]; then
  echo "Error: WIN_PASSWORD environment variable is not set."
  exit 1
fi

# Set script directory
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display help
usage() {
  echo "Usage: $0 --org=<org_name>"
  echo "Options:"
  echo "  --org=<org_name>   GitHub organization name"
  echo "  --help             Show this help message"
  exit 0
}

# Parse arguments
ORG=""
for arg in "$@"; do
  case $arg in
    --org=*)
      ORG="${arg#*=}"
      shift
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage
      ;;
  esac
done

# Ensure ORG is set
if [[ -z "$ORG" ]]; then
  echo "Error: Missing required argument --org=<org_name>." >&2
  usage
fi

# Function to get the IP address for a given VM ID
function get_windows_vm_ip {
  local vm_id=$1
  ssh $PROXMOX_SSH_USER@$PROXMOX_HOST -o LogLevel=QUIET -t "qm agent $vm_id network-get-interfaces" |
    jq -r '.[] | .["ip-addresses"][]? | select(.["ip-address"] | startswith("192.168")) | .["ip-address"]' | head -n1
}

# Function to process all Windows VMs
function process_windows_vms {
  # Capture Windows VM IDs from Terraform
  local WINDOWS_VMS_JSON=$(terraform -chdir=$here/terraform output -json windows_vms)
  WINDOWS_IDS=($(echo "$WINDOWS_VMS_JSON" | jq -r '.ids[]'))
  WINDOWS_NAMES=($(echo "$WINDOWS_VMS_JSON" | jq -r '.names[]'))

  for vm_id in $WINDOWS_IDS; do
    echo "Fetching IP for VM ID: $vm_id"
    ip=$(get_windows_vm_ip "$vm_id")
    if [[ -n "$ip" ]]; then
      echo "Windows VM $vm_id IP: $ip"
      WINDOWS_IPS+=("$ip")
    else
      echo "Failed to fetch IP for VM $vm_id"
    fi
  done
}

# Get GitHub Actions runner registration token
RUNNER_TOKEN=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/orgs/$ORG/actions/runners/registration-token" | jq -r .token)

if [[ -z "$RUNNER_TOKEN" || "$RUNNER_TOKEN" == "null" ]]; then
  echo "Error: Failed to retrieve runner token. Ensure token has admin:org permission" >&2
  exit 1
fi

# Run Terraform with the retrieved values
terraform -chdir=$here/terraform apply -var="runner_token=$RUNNER_TOKEN" -var="runner_org=$ORG"

# Sleep here to give the WindowsVM time to get an IP assigned
sleep 10s

WINDOWS_IPS=()
process_windows_vms

for i in "${!WINDOWS_IPS[@]}"; do
    VM_IP="${WINDOWS_IPS[i]}"
    VM_NAME="${WINDOWS_NAMES[i]}"

    echo "Ansible configuring VM: $VM_NAME ($VM_IP)"

    ansible-playbook $here/ansible/action-runner.yaml -i "$VM_IP," \
      -e "ansible_user=Administrator ansible_password=$WINRM_PASSWORD ansible_connection=winrm ansible_winrm_server_cert_validation=ignore ansible_winrm_port=5985" \
      -e "runner_org=$ORG runner_token=$RUNNER_TOKEN runner_name=$VM_NAME"
  done
