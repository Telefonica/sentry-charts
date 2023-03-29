#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

function usage() {
  echo "Usage: $(basename $0) [-h|--help]"
  echo "Process the Sentry Helm Chart with overrides for sentry-pre and output the Kubernetes YAML"
  echo ""
  echo "  -h, --help  Show this help"
  echo ""
  echo "TEF_IAAC environment variable must contain the path for local tef-iaac repository"
  echo "TF_MODULE_KUBENOVUM environment variable must contain the path for local tf-module-kubenovum repository"
  echo ""
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi


if [[ -z "$TF_MODULE_KUBENOVUM" || -z "$TEF_IAAC" ]]; then
  echo 'ERROR: $TF_MODULE_KUBENOVUM and $TEF_IAAC must contain the path for those repositories'
  exit 1
fi

helm -n tooling-pre template sentry-pre sentry -f "$TF_MODULE_KUBENOVUM/k8s-setup/chart-values/sentry.yaml" -f overrides/serviceaccount.yaml -f overrides/images.yaml -f overrides/sentry-pre-tooling-pre.yaml -f "$TEF_IAAC/environments/azure/northeurope09/prd.tooling/blue-k8s-infra/chart-values-override/sentry.yaml"
