#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

source ./bash_util.sh

function usage() {
  echo "Usage: $(basename "$0") [-h][-k PATH][-t PATH][-s TEMPLATE]"
  echo "Process the Sentry Helm Chart with overrides for sentry-dev and output the Kubernetes YAML"
  echo ""
  echo "  -h         Show this help"
  echo "  -k PATH    tf_module_kubenovum repository path. If not present it will try to look for it in the parent dir"
  echo "  -t PATH    tef_iaac repository path. If not present it will try to look for it in the parent dir"
  echo "  -s TEMPLATE Show only specific template (e.g., templates/hooks/sentry-novum-bootstrap.job.yaml)"
  echo ""
}

TF_MODULE_KUBENOVUM=
TEF_IAAC=
SHOW_ONLY_TEMPLATE=

while getopts "hk:t:s:" OPT; do
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
    s)
      SHOW_ONLY_TEMPLATE="$OPTARG"
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

helm_dependency_check "charts/sentry"

HELM_CMD="helm -n common template sentry charts/sentry -f \"$TF_MODULE_KUBENOVUM/k8s-setup/chart-values/sentry.yaml\" -f overrides/images.yaml -f overrides/sentry-dev.yaml -f \"$TEF_IAAC/environments/azure/northeurope04/dev.global/blue-k8s-infra/chart-values-override/sentry.yaml\" -f overrides/requests.yaml"

if [ -n "$SHOW_ONLY_TEMPLATE" ]; then
  HELM_CMD="$HELM_CMD --show-only $SHOW_ONLY_TEMPLATE"
fi

eval $HELM_CMD
