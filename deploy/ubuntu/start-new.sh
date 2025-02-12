#!/bin/bash -e
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

# Get GitHub Actions runner registration token
RUNNER_TOKEN=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/orgs/$ORG/actions/runners/registration-token" | jq -r .token)

if [[ -z "$RUNNER_TOKEN" || "$RUNNER_TOKEN" == "null" ]]; then
  echo "Error: Failed to retrieve runner token. Ensure token has admin:org permission" >&2
  exit 1
fi

# Run Terraform with the retrieved values
terraform -chdir=$here apply -var="runner_token=$RUNNER_TOKEN" -var="runner_org=$ORG"
