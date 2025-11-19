#!/usr/bin/env bash
set -e

# Usage: ./deploy.sh <dockerhub_user> <image_repo> <tag>
DOCKERHUB_USER="$1"
IMAGE_REPO="$2"
TAG="$3"
COMPOSE_FILE="/home/ubuntu/remote-docker-compose.yml"  # change to your path on remote

echo "Deploy: pulling image ${DOCKERHUB_USER}/${IMAGE_REPO}:${TAG}"
# Update remote compose to use exact tag (optional)
# Here we replace :latest with the exact tag so deployment is deterministic
sed -i "s|image: ${DOCKERHUB_USER}/${IMAGE_REPO}.*|image: ${DOCKERHUB_USER}/${IMAGE_REPO}:${TAG}|g" "$COMPOSE_FILE"

# pull and restart
docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d
echo "Deployment complete."
