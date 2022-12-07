#!/usr/bin/env bash

# Set argocd version if env is empty
# Select desired TAG from https://github.com/argoproj/argo-cd/releases
if [ -z "$ARGOCD_VERSION" ]; then
  export ARGOCD_VERSION=v2.5.2
fi

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$ARGOCD_VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
