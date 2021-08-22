#!/usr/bin/env bash

# prevent souring of this script, only allow execution
$(return >/dev/null 2>&1)
test "$?" -eq "0" && { echo "This script should only be executed." >&2; exit 1; }

# exit on errors, undefined variables, ensure errors in pipes are not hidden
set -Eeuo pipefail

# set log id and use shared log function for readable logs
declare mydir
mydir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# helper functions
log() {
  local time
  # second-precision is enough
  time=$(date -u +%y-%m-%dT%H:%M:%SZ)
  echo >&2 -e "${time} [delete-gcloud-vm] ${1-}"
}

msg() {
  echo >&2 -e "${1-}"
}

# work
declare vm_name="${1:-gnosis-safe}"
declare ssh_cfg="${mydir}/gcloud-vm-ssh.cfg"

test -z "${GCLOUD_PROJECT:-}" && { msg "Missing environment variable GCLOUD_PROJECT"; exit 1; }

# gcloud configs
declare gcloud_project="--project=${GCLOUD_PROJECT}"
declare gcloud_zone="--zone=europe-west6-a"

log "delete VM"
gcloud compute instances delete ${vm_name} \
  ${gcloud_project} \
  ${gcloud_zone}

log "NOTE: any static IP which was assigned to this VM is kept so DNS isn't broken, please delete the IP manually if needed"

log "finished"
