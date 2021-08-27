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
  echo >&2 -e "${time} [build-and-run-gnosis-safe] ${1-}"
}

msg() {
  echo >&2 -e "${1-}"
}

# work

test -n "${GNOSIS_SAFE_ENVIRONMENT:-}" || { msg "Missing environment variable GNOSIS_SAFE_ENVIRONMENT"; exit 1; }

declare gs_project="gnosis-safe-${GNOSIS_SAFE_ENVIRONMENT}"
declare gs_env="${GNOSIS_SAFE_ENVIRONMENT}"
declare gs_web_cfg="${mydir}/configs/gnosis-safe-react.env.${gs_env}"
declare gs_cgw_cfg="${mydir}/configs/gnosis-safe-client-gateway.env.${gs_env}"
declare gs_txs_cfg="${mydir}/configs/gnosis-safe-transaction-service.env.${gs_env}"
declare gs_cfs_cfg="${mydir}/configs/gnosis-safe-config-service.env.${gs_env}"

test -f "${gs_web_cfg}" || { msg "Missing environment configuration file ${gs_web_cfg}"; exit 1; }
test -f "${gs_cgw_cfg}" || { msg "Missing environment configuration file ${gs_cgw_cfg}"; exit 1; }
test -f "${gs_txs_cfg}" || { msg "Missing environment configuration file ${gs_txs_cfg}"; exit 1; }
test -f "${gs_cfs_cfg}" || { msg "Missing environment configuration file ${gs_cfs_cfg}"; exit 1; }

if [ "${GNOSIS_SAFE_ENVIRONMENT}" != "local" ] && [ -z "${GNOSIS_SAFE_DOMAIN}" ]; then
  msg "Missing environment variable GNOSIS_SAFE_DOMAIN"
  exit 1
fi

function docker_compose() {
  if docker-compose 2> /dev/null; then
    docker-compose $@
  else
    # use docker-compose container when its not available locally
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$PWD:$PWD" -w="$PWD" \
      -e GNOSIS_SAFE_DOMAIN="${GNOSIS_SAFE_DOMAIN}" \
      -e GNOSIS_SAFE_ENVIRONMENT="${GNOSIS_SAFE_ENVIRONMENT}" \
      docker/compose:1.29.2 $@
  fi
}

log "copy gnosis-safe-react into docker-gnosis-safe-react/"
rsync -rltuv vendor/github.com/hoprnet/safe-react docker-gnosis-safe-react/

log "copy config files into the correct contexts"
cp "${gs_web_cfg}" .env
cp "${gs_web_cfg}" docker-gnosis-safe-react/safe-react/.env
cp "${gs_cgw_cfg}" vendor/github.com/gnosis/safe-client-gateway/.env
cp "${gs_txs_cfg}" vendor/github.com/gnosis/safe-transaction-service/.env
cp "${gs_cfs_cfg}" vendor/github.com/gnosis/safe-config-service/.env

log "stop potentially running services"
docker_compose -p ${gs_project} stop

log "delete lb and web container and static files volume to ensure volume changes are picked up"
docker_compose -p ${gs_project} rm -f lb react
docker volume rm -f ${gs_project}_caddy-react-files

log "build gnosis safe images"
docker_compose -p ${gs_project} build --parallel

log "create gnosis safe services"
docker_compose -p ${gs_project} up --no-start --build

log "start gnosis safe services"
docker_compose -p ${gs_project} start

log "finished"
