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
declare vm_name="${1:-gnosis-safe}"
declare vm_name_ip="${vm_name}-ip"
declare ssh_cfg="${mydir}/gcloud-vm-ssh.cfg"

test -f "${ssh_cfg}" && { msg "${ssh_cfg} already exists, delete to force creation of new VM"; exit 1; }
test -z "${GCLOUD_PROJECT:-}" && { msg "Missing environment variable GCLOUD_PROJECT"; exit 1; }

# gcloud configs
declare gcloud_project="--project=${GCLOUD_PROJECT}"
declare gcloud_zone="--zone=europe-west6-a"
declare gcloud_region="--region=europe-west6"
declare gcloud_machine_type="--machine-type=n2-standard-8"
declare gcloud_meta="--metadata=google-logging-enabled=true,google-monitoring-enabled=true,enable-oslogin=true --maintenance-policy=MIGRATE"
declare gcloud_tags="--tags=portainer,healthcheck"
declare gcloud_bootdisk="--boot-disk-size=100GB --boot-disk-type=pd-standard"
declare gcloud_image="--image-family=cos-89-lts --image-project=cos-cloud"
declare gcloud_shielded_vm="--shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring"

log "check if GCP static IP address exists"
if ! gcloud compute addresses describe ${vm_name_ip} ${gcloud_project} ${gcloud_region}; then
  log "create GCP static IP address"
  gcloud compute addresses create ${vm_name_ip} \
    ${gcloud_project} \
    ${gcloud_region}
fi

declare static_ip=$(gcloud compute addresses describe ${vm_name_ip} ${gcloud_project} ${gcloud_region} | head -n 1 | awk '{ print $2; }')
log "using GCP static IP ${static_ip}"

log "check if GCP VM exists"
if ! gcloud compute instances describe ${vm_name} ${gcloud_project} ${gcloud_zone}; then
  log "create GCP VM "
  gcloud compute instances create ${vm_name} \
    ${gcloud_project} \
    ${gcloud_zone} \
    ${gcloud_machine_type} \
    ${gcloud_meta} \
    ${gcloud_tags} \
    ${gcloud_bootdisk} \
    ${gcloud_image} \
    ${gcloud_shielded_vm} \
    --address=${vm_name_ip}
fi

declare cf_zone="${CF_ZONE:-}"
declare cf_email="${CF_EMAIL:-}"
declare cf_apikey="${CF_APIKEY:-}"
declare cf_domain="${CF_DOMAIN:-}"
declare domains="${cf_domain} transaction-service-${cf_domain} client-gateway-${cf_domain} config-service-${cf_domain}"

log "check if Cloudflare credentials are configured"
if [ -z "${cf_zone}" ] || [ -z "${cf_email}" ] || [ -z "${cf_apikey}" ] || [ -z "${cf_domain}" ]; then
  log "skipping Cloudflare DNS entry (not configured), requires env vars CF_ZONE, CF_EMAIL, CF_APIKEY, CF_DOMAIN"
else
  for domain in ${domains}; do
    curl -X POST \
      "https://api.cloudflare.com/client/v4/zones/${cf_zone}/dns_records" \
      -H "X-Auth-Email: ${cf_email}" \
      -H "X-Auth-Key: ${cf_apikey}" \
      -H "Content-Type: application/json" \
      --data \
      '{"type":"A","name":"'${domain}'","content":"'${static_ip}'","ttl":120,"priority":10,"proxied":false}'
  done
  echo ""
fi

log "finished"
