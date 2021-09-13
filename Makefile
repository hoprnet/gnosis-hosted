.DEFAULT_GOAL := help

project := gnosis

prepare_production: ## upload configuration files to Docker host when using production environment
	@[ -z "${ssh_user}" ] && { echo >&2 "Error: missing parameter <ssh_user>"; exit 1; } || :
	@[ -z "${ssh_host}" ] && { echo >&2 "Error: missing parameter <ssh_host>"; exit 1; } || :
	scp \
		Caddyfile.production \
		configs/gnosis-safe-react.env.production \
		configs/gnosis-safe-transaction-service.env.production \
		configs/gnosis-safe-client-gateway.env.production \
		configs/gnosis-safe-config-service.env.production \
		${ssh_user}@${ssh_host}:
	ssh ${ssh_user}@${ssh_host} \
		"sudo mkdir -p /var/lib/gnosis-safe && \
		 sudo mv \
		   Caddyfile.production \
		   configs/gnosis-safe-react.env.production \
		   configs/gnosis-safe-transaction-service.env.production \
		   configs/gnosis-safe-client-gateway.env.production \
		   configs/gnosis-safe-config-service.env.production \
		   /var/lib/gnosis-safe"

start : ## create and start local Docker nodes
	# ensure the environment is set
	@[ -z "${GNOSIS_ENVIRONMENT}" ] && { echo >&2 "Error: missing environment variable GNOSIS_ENVIRONMENT"; exit 1; } || :
	# ensure a support email is set when deploying to production
	@[ "${GNOSIS_ENVIRONMENT}" = "production" ] && [ -z "${GNOSIS_SAFE_SUPPORT_EMAIL}"] && { echo >&2 "Error: missing environment variable GNOSIS_SAFE_SUPPORT_EMAIL"; exit 1; } || :
	# ensure a domain is set when deploying to production
	@[ "${GNOSIS_ENVIRONMENT}" = "production" ] && [ -z "${GNOSIS_SAFE_DOMAIN}"] && { echo >&2 "Error: missing environment variable GNOSIS_SAFE_DOMAIN"; exit 1; } || :
	# build images
	docker-compose -p ${project} -f docker-compose.yml -f docker-compose.${GNOSIS_ENVIRONMENT}.yml build
	# build containers and setup volumes
	docker-compose -p ${project} -f docker-compose.yml -f docker-compose.${GNOSIS_ENVIRONMENT}.yml up --no-start --build
	# start containers
	docker-compose -p ${project} -f docker-compose.yml -f docker-compose.${GNOSIS_ENVIRONMENT}.yml start

stop: ## stop local Docker nodes
	docker-compose -p ${project} stop
	# remove static files volume so changes are picked up next time
	docker-compose -p ${project} rm -f caddy react
	docker volume rm -f ${project}_caddy-react-files

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help start stop prepare_production
