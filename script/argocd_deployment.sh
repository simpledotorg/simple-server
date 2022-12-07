#!/usr/bin/env bash

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <argocd-endpoint> <argocd-user> <argocd-password> <image-tag>" >&2
  exit 1
fi

ARGOCD_ENDPOINT=$1
ARGOCD_USERNAME=$2
ARGOCD_PASSWORD=$3
IMAGE_TAG=$4

DEFAULT_ARGOCD_VERSION=v2.5.2

# Install argocd if not installed
if ! command -v argocd &> /dev/null
then
  # Set argocd version if env is empty
  # Select desired TAG from https://github.com/argoproj/argo-cd/releases
  if [ -z "$ARGOCD_VERSION" ]; then
    export ARGOCD_VERSION=$DEFAULT_ARGOCD_VERSION # Set default version
  fi

  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64
  sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm argocd-linux-amd64
fi

# Argocd login
argocd login $ARGOCD_ENDPOINT \
  --username $ARGOCD_USERNAME \
  --password $ARGOCD_PASSWORD \
  --insecure --config /home/argocd/.config/argocd/config

# Argocd set simple server image
argocd app set simple-server --helm-set image.tag=$IMAGE_TAG --config /home/argocd/.config/argocd/config

# Argocd wait for sync
argocd app wait simple-server --config /home/argocd/.config/argocd/config
