#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-atomy/dystopia-server}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

docker build \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  "$(dirname "$(realpath "$0")")/.."

echo "Built ${IMAGE_NAME}:${IMAGE_TAG}"
