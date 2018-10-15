#!/bin/bash
set -e

IMAGE_NAME="travelbank/api"
FEATURE_NAME=${1/\//-}
IMAGE_TAG="$IMAGE_NAME:$FEATURE_NAME"

deploy_api() {
  echo "=> deploying api to kubernetes"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    -n api \
    set image deployment/api \
    api="$IMAGE_TAG"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    rollout status deployment/api -n api || true
}

deploy_scheduler() {
  echo "=> deploying scheduler to kubernetes"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    -n api \
    set image deployment/scheduler \
    scheduler="$IMAGE_TAG"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    rollout status deployment/scheduler -n api || true
}

deploy_worker() {
  echo "=> deploying scheduler to kubernetes"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    -n api \
    set image deployment/worker \
    worker="$IMAGE_TAG"

  kubectl \
    --kubeconfig ~/.kube/$1 \
    rollout status deployment/worker -n api || true
}

if [[ $2 == 'api' ]]; then
  deploy_api $3
elif [[ $2 == 'scheduler' ]]; then
  deploy_scheduler $3
elif [[ $2 == 'worker' ]]; then
  deploy_worker $3
else
  echo 'no valid deployment given, skipping'
fi
