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
  echo >&2 -e "${time} [create-gcloud-vm] ${1-}"
}

msg() {
  echo >&2 -e "${1-}"
}

# work
declare vm_name="hosted-gnosis-safe"
declare ssh_cfg="${mydir}/gcloud-vm-ssh.cfg"

test -f "${ssh_cfg}" && { msg "${ssh_cfg} already exists, delete to force creation of new VM"; exit 1; }
test -z "${GCLOUD_PROJECT:-}" && { msg "Missing environment variable GCLOUD_PROJECT"; exit 1; }

# gcloud configs
declare gcloud_project="--project=${GCLOUD_PROJECT}"
declare gcloud_zone="--zone=europe-west6-a"
declare gcloud_region="--region=europe-west6"
declare gcloud_machine_type="--machine-type=e2-medium"
declare gcloud_meta="--metadata=google-logging-enabled=true,google-monitoring-enabled=true,enable-oslogin=true --maintenance-policy=MIGRATE"
declare gcloud_tags="--tags=portainer,healthcheck"
declare gcloud_bootdisk="--boot-disk-size=10GB --boot-disk-type=pd-standard"
declare gcloud_image="--image-family=cos-89-lts --image-project=cos-cloud"
declare gcloud_shielded_vm="--shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"

log "create new VM"
gcloud compute instances create ${vm_name} \
  ${gcloud_project} \
  ${gcloud_zone} \
  ${gcloud_machine_type} \
  ${gcloud_meta} \
  ${gcloud_tags} \
  ${gcloud_bootdisk} \
  ${gcloud_image} \
  ${gcloud_shielded_vm}

log "finished"
