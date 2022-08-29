#!/bin/bash

# IMPORTANT: KUBECONFIG as arg...

if [[ -z $1 ]]; then
    echo "Set \$1 to your kube context"
    exit 1
fi

# Based on https://access.crunchydata.com/documentation/postgres-operator/latest/installation/kustomize/

kubectl apply --context $1 -k kustomize/install/namespace
kubectl apply --context $1 --server-side -k kustomize/install/default
