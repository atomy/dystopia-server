#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-atomy/dystopia-server}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

docker push "${IMAGE_NAME}:${IMAGE_TAG}"

echo "Pushed ${IMAGE_NAME}:${IMAGE_TAG}"
