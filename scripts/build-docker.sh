#!/bin/bash
set -e

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
LATEST_COMMIT=$(git rev-parse --short HEAD)
IMAGE_NAME="travelbank/api"
IMAGE_TAGS=($GIT_BRANCH $LATEST_COMMIT)

echo "=> Building docker image for $IMAGE_NAME:$GIT_BRANCH-$LATEST_COMMIT"

docker build -t $IMAGE_NAME .

for tag in ${IMAGE_TAGS[@]}; do
  docker tag $IMAGE_NAME $IMAGE_NAME:$tag
done

for tag in ${IMAGE_TAGS[@]}; do
  docker push $IMAGE_NAME:$tag
done
