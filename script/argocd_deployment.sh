#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <argocd-endpoint> <argocd-user> <argocd-password>" >&2
  exit 1
fi

ARGOCD_ENDPOINT=$1
ARGOCD_USERNAME=$2
ARGOCD_PASSWORD=$3

# Argocd login
argocd login $ARGOCD_ENDPOINT \
  --username $ARGOCD_USERNAME \
  --password $ARGOCD_PASSWORD \
  --insecure --config /home/argocd/.config/argocd/config

# Argocd set simple server image
argocd app set simple-server --helm-set image=simpledotorg/server:$GITHUB_SHA --config /home/argocd/.config/argocd/config

# Argocd wait for sync
argocd app wait simple-server --config /home/argocd/.config/argocd/config
