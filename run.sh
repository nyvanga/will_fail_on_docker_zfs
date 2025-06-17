#!/usr/bin/env bash

set -euo pipefail

DIR=$(cd "$(dirname "${0}")" && pwd)
# Using /tmp/<iso date and time> to ensure clean starting point every time
TMP_DIR="${DIR}/tmp/$(date +%Y.%m.%d_%H.%M.%S)"

NETWORK_NAME="test_docker_dind"

CERTS_CLIENT_DIR="${TMP_DIR}/certs"

function setup() {
	echo ">>> Creating tmp directory ${TMP_DIR}"
	mkdir -pv "${TMP_DIR}"

	echo ">>> Creating network ${NETWORK_NAME}"
	docker network create "${NETWORK_NAME}"
}

function launch_dind() {
	# See https://hub.docker.com/_/docker
	# Under: "Start a daemon instance"
	echo ">>> Launching docker-in-docker"
	docker run --privileged --name test_docker_dind -d --rm \
		--network "${NETWORK_NAME}" --network-alias docker \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v "${TMP_DIR}/certs-ca:/certs/ca" \
		-v "${CERTS_CLIENT_DIR}:/certs/client" \
		-v "${TMP_DIR}/lib_docker:/var/lib/docker" \
		docker:dind
}

function launch_dind_tmpfs() {
	# See https://hub.docker.com/_/docker
	# Under: "Start a daemon instance"
	echo ">>> Launching docker-in-docker"
	docker run --privileged --name test_docker_dind -d --rm \
		--network "${NETWORK_NAME}" --network-alias docker \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v "${TMP_DIR}/certs-ca:/certs/ca" \
		-v "${CERTS_CLIENT_DIR}:/certs/client" \
		--tmpfs /var/lib/docker \
		docker:dind
}

function launch_dind_zfs() {
	# See https://hub.docker.com/_/docker
	# Under: "Start a daemon instance"
	echo ">>> Launching docker-in-docker"
	docker run --privileged --name test_docker_dind -d --rm \
		--network "${NETWORK_NAME}" --network-alias docker \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v "${TMP_DIR}/certs-ca:/certs/ca" \
		-v "${CERTS_CLIENT_DIR}:/certs/client" \
		-v "${TMP_DIR}/lib_docker:/var/lib/docker" \
		-v "${DIR}/zfs-daemon.json:/etc/docker/daemon.json:ro" \
		docker:dind
}

function launch() {
	local type="${1:-}"
	if [[ "${type}" == "tmpfs" ]]; then
		launch_dind_tmpfs
	elif [[ "${type}" == "zfs" ]]; then
		launch_dind_zfs
	else
		launch_dind
	fi
}

function wait_for_dind() {
	echo ">>> Waiting to make sure docker-in-docker is launched"
	while [[ ! -f "${CERTS_CLIENT_DIR}/ca.pem" ]]; do
		sleep 2
	done
	echo "Found '${CERTS_CLIENT_DIR}/ca.pam', lets continue"

	echo ">> Docker info"
	docker exec test_docker_dind docker info
}

function build() {
	# See https://hub.docker.com/_/docker
	# Under: "Connect to it from a second container"
	echo ">>> Launching docker-client and building dockerfile on docker-in-docker"
	docker run --rm --network "${NETWORK_NAME}" \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v "${CERTS_CLIENT_DIR}:/certs/client:ro" \
		-v "${DIR}/build.sh:/test/build.sh:ro" \
		-v "${DIR}/Dockerfile:/test/Dockerfile:ro" \
		--entrypoint /test/build.sh \
		docker:latest
}

function teardown() {
	echo ">>> Shutdown docker-in-docker"
	docker stop test_docker_dind || true

	echo ">>> Remove network ${NETWORK_NAME}"
	docker network rm "${NETWORK_NAME}" || true
}

case "${1:-}" in
	test)
		trap teardown EXIT
		setup
		launch "${2:-}"
		wait_for_dind
		build
		;;

	launch)
		setup
		launch "${2:-}"
		wait_for_dind
		;;

	teardown)
		teardown
		;;

	*)
		echo "Usage: $(basename "${0}") <test|launch|teardown> < empty |tmpfs|zfs>"
		;;
esac
