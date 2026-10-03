#!/usr/bin/env bash
set -euo pipefail

# Helper script to build and deploy MinIO image directly for MicroK8s
# Usage:
#   ./scripts/deploy-to-microk8s.sh [registry|import] [image-tag]

MODE="${1:-registry}" # Options: registry (default, pushes to localhost:32000) or import (imports into microk8s containerd)
TAG="${2:-microk8s-latest}"

LOCAL_REGISTRY="localhost:32000"
IMAGE_NAME="minio"
FULL_IMAGE="${LOCAL_REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "=========================================="
echo " Building MinIO Image for MicroK8s"
echo " Mode:      ${MODE}"
echo " Image tag: ${FULL_IMAGE}"
echo "=========================================="

# Build image locally with Docker
docker build -t "${FULL_IMAGE}" -t "${IMAGE_NAME}:${TAG}" .

if [ "${MODE}" = "registry" ]; then
	echo "Pushing image to MicroK8s built-in registry (${LOCAL_REGISTRY})..."
	docker push "${FULL_IMAGE}"
	echo ""
	echo "Image successfully pushed to MicroK8s registry: ${FULL_IMAGE}"
	echo "In your Kubernetes manifests (e.g. Tenant or Deployment), configure:"
	echo "  image: ${FULL_IMAGE}"
elif [ "${MODE}" = "import" ]; then
	echo "Importing image directly into MicroK8s containerd..."
	docker save "${IMAGE_NAME}:${TAG}" | microk8s ctr image import -
	echo ""
	echo "Image imported into MicroK8s containerd: ${IMAGE_NAME}:${TAG}"
	echo "In your Kubernetes manifests (e.g. Tenant or Deployment), configure:"
	echo "  image: ${IMAGE_NAME}:${TAG}"
	echo "  imagePullPolicy: IfNotPresent"
else
	echo "Unknown mode: ${MODE}. Supported modes: 'registry' or 'import'"
	exit 1
fi

echo "Done!"
