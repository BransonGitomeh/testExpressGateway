#!/bin/bash
set -e

IMAGE_NAME="travelbank/api"
FEATURE_NAME=${1/\//-}
TAGS=($FEATURE_NAME $2)

echo "=> Publishing docker image $IMAGE_NAME:$1 sha:$2"

for tag in ${TAGS[@]}; do
  docker tag $IMAGE_NAME $IMAGE_NAME:$tag
done

for tag in ${TAGS[@]}; do
  docker push $IMAGE_NAME:$tag
done
