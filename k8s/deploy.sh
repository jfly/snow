#!/usr/bin/env bash

set -euo pipefail

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml

for f in *.yaml; do
	kubectl apply -f "$f"
done
