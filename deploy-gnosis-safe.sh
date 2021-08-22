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
  echo >&2 -e "${time} [deploy-gnosis-safe] ${1-}"
}

msg() {
  echo >&2 -e "${1-}"
}

# work
declare vm_name="${1:-gnosis-safe}"

test -z "${GCLOUD_PROJECT:-}" && { msg "Missing environment variable GCLOUD_PROJECT"; exit 1; }
test -z "${GNOSIS_SAFE_DOMAIN:-}" && { msg "Missing environment variable GNOSIS_SAFE_DOMAIN"; exit 1; }

declare gnosis_safe_domain="${GNOSIS_SAFE_DOMAIN}"

# gcloud configs
declare gcloud_project="--project=${GCLOUD_PROJECT}"
declare gcloud_zone="--zone=europe-west6-a"

# utility configs
declare ssh_args="--force-key-file-overwrite --ssh-key-expire-after=2m ${gcloud_zone} ${gcloud_project}"
declare remote_path="/var/lib/gnosis-safe"

declare gssh="gcloud compute ssh ${ssh_args}"
declare gscp="gcloud compute scp ${ssh_args}"

log "build tarball of local files"
declare tarball="$(mktemp -d)/gnosis.tar.xz"
tar --exclude-vcs -caf "${tarball}" .

log "upload tarball to server"
${gscp} ${tarball} ${vm_name}:~/
${gssh} ${vm_name} --command="mkdir -p ~/gnosis-hosted-repo"
${gssh} ${vm_name} --command="tar -xf ~/gnosis.tar.xz -C ~/gnosis-hosted-repo"
${gssh} ${vm_name} --command="rm ~/gnosis.tar.xz"
rm ${tarball}

log "move repo to ${remote_path}"
${gssh} ${vm_name} --command="sudo rm -rf ${remote_path}"
${gssh} ${vm_name} --command="sudo mv ~/gnosis-hosted-repo ${remote_path}"
${gssh} ${vm_name} --command="sudo chown -R root:root ${remote_path}"

log "execute build and run script"
declare run_script="build-and-run-gnosis-safe.sh"
if [ "${GNOSIS_SAFE_RUN_ONLY:-}" = "true" ]; then
  run_script="run-gnosis-safe.sh"
fi

${gssh} ${vm_name} --command="sudo sh -c \"
  cd ${remote_path} && \
  env \
    GNOSIS_SAFE_ENVIRONMENT=production \
    GNOSIS_SAFE_DOMAIN=${gnosis_safe_domain} \
    bash ./${run_script} \
  \""

log "finished"
