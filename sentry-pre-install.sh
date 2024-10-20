#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

source ./bash_util.sh

NAMESPACE=tooling-pre

function usage() {
  echo "Usage: $(basename "$0") [-h][-u][-y][-d][-r]"
  echo "Install sentry-pre in $NAMESPACE"
  echo ""
  echo "  -h         Show this help"
  echo "  -u         Do an upgrade instead of an install"
  echo "  -y         Don't ask for confirmation"
  echo "  -d         Enable debug output"
  echo "  -r         Do a dry-run, don't install or upgrade anything"
  echo "  -k PATH    tf_module_kubenovum repository path. If not present it will try to look for it in the parent dir"
  echo "  -t PATH    tef_iaac repository path. If not present it will try to look for it in the parent dir"
  echo ""
}


HELM_ACTION=install
declare -a HELM_UPGRADE_OPTIONS
ASK_CONFIRMATION=yes
DEBUG_OPTION=
DRY_RUN_OPTION=
TF_MODULE_KUBENOVUM=
TEF_IAAC=

while getopts "huydrk:t:" OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    u)
      HELM_ACTION=upgrade
      HELM_UPGRADE_OPTIONS=("--reset-values")
      ;;
    y)
      ASK_CONFIRMATION=no
      ;;
    d)
      DEBUG_OPTION="--debug"
      ;;
    r)
      DRY_RUN_OPTION="--dry-run"
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

echo "Using tf_module_kubenovum  ->  $TF_MODULE_KUBENOVUM"
echo "Using tef_iaac             ->  $TEF_IAAC"
echo ""

if [[ "$ASK_CONFIRMATION" == "yes" && -z "$DRY_RUN_OPTION" ]]; then
  read -r -p "You are going to perform an \"helm $HELM_ACTION\" operation in $NAMESPACE. Are you sure? [y/N] " OPT
  if [[ "$OPT" != "y" && "$OPT" != "Y" ]]; then
    echo "Aborted"
    exit 0
  fi
fi

kubeswitch tooling/pre
helm_dependency_check "charts/sentry"

HELM_DRIVER=configmap helm -n $NAMESPACE $HELM_ACTION sentry-pre charts/sentry "${HELM_UPGRADE_OPTIONS[@]}" --timeout 10m $DRY_RUN_OPTION $DEBUG_OPTION -f "$TF_MODULE_KUBENOVUM/k8s-setup/chart-values/sentry.yaml" -f overrides/serviceaccount.yaml -f overrides/images.yaml -f overrides/sentry-pre-tooling-pre.yaml -f "$TEF_IAAC/environments/azure/northeurope09/prd.tooling/blue-k8s-infra/chart-values-override/sentry.yaml" -f overrides/requests.yaml
