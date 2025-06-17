#!/usr/bin/env ash

DOCKER_HOST=tcp://docker:2376
CA_FILE="${DOCKER_TLS_CERTDIR}/client/ca.pem"
CERT_FILE="${DOCKER_TLS_CERTDIR}/client/cert.pem"
KEY_FILE="${DOCKER_TLS_CERTDIR}/client/key.pem"

echo ">>> Creating test_context"
docker context create test_context \
	--docker "host=${DOCKER_HOST},ca=${CA_FILE},cert=${CERT_FILE},key=${KEY_FILE}"

echo ">>> Creating test_builder"
docker buildx create --name test_builder \
	--driver docker-container \
	--driver-opt network=host \
	--bootstrap --use \
	--platform linux/amd64,linux/arm64 \
	test_context

echo ">> Docker info"
docker --context test_context info

echo ">> Building dockerfile"
docker buildx build --progress=plain --no-cache --output local /test
