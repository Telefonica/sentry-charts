#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

source ./bash_util.sh

function usage() {
  echo "Usage: $(basename $0) [-h][-k PATH][-t PATH]"
  echo "Process the Sentry Helm Chart with overrides for sentry-pre and output the Kubernetes YAML"
  echo ""
  echo "  -h         Show this help"
  echo "  -k PATH    tf_module_kubenovum repository path. If not present it will try to look for it in the parent dir"
  echo "  -t PATH    tef_iaac repository path. If not present it will try to look for it in the parent dir"
  echo ""
}

TF_MODULE_KUBENOVUM=
TEF_IAAC=

while getopts "hk:t:" OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    k)
      TF_MODULE_KUBENOVUM="$OPTARG"
      ;;
    t)
      TEF_IAAC="$OPTARG"
      ;;
    *)
      echo "ERROR: Unknown option"
      echo ""
      usage
      exit 1
  esac
done
shift $((OPTIND-1))

find_and_validate_external_repositories

helm -n tooling-pre template sentry-pre sentry -f "$TF_MODULE_KUBENOVUM/k8s-setup/chart-values/sentry.yaml" -f overrides/serviceaccount.yaml -f overrides/images.yaml -f overrides/sentry-pre-tooling-pre.yaml -f "$TEF_IAAC/environments/azure/northeurope09/prd.tooling/blue-k8s-infra/chart-values-override/sentry.yaml"
