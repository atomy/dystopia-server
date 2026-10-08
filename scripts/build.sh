#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-atomy/dystopia-server}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
# Unique by default so the Steam install layer is never served stale from cache
DYS_BUILDID="${DYS_BUILDID:-local-$(date +%Y%m%d%H%M%S)}"

docker build \
  --build-arg "DYS_BUILDID=${DYS_BUILDID}" \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  "$(dirname "$(realpath "$0")")/.."

echo "Built ${IMAGE_NAME}:${IMAGE_TAG}"
