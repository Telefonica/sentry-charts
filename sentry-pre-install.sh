#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

NAMESPACE=tooling-pre

function usage() {
  echo "Usage: $(basename $0) [-h][-u][-y][-d][-r]"
  echo "Install sentry-pre in $NAMESPACE"
  echo ""
  echo "  -h  Show this help"
  echo "  -u  Do an upgrade instead of an install"
  echo "  -y  Don't ask for confirmation"
  echo "  -d  Enable debug output"
  echo "  -r  Do a dry-run, don't install or upgrade anything"
  echo ""
  echo "TEF_IAAC environment variable must contain the path for local tef-iaac repository"
  echo "TF_MODULE_KUBENOVUM environment variable must contain the path for local tf-module-kubenovum repository"
  echo ""
}

HELM_ACTION=install
ASK_CONFIRMATION=yes
DEBUG_OPTION=
DRY_RUN_OPTION=

while getopts "huydr" OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    u)
      HELM_ACTION=upgrade
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
    *)
      echo "ERROR: Unknown option"
      echo ""
      usage
      exit 1
  esac
done
shift $((OPTIND-1))

if [[ -z "$TF_MODULE_KUBENOVUM" || -z "$TEF_IAAC" ]]; then
  echo 'ERROR: $TF_MODULE_KUBENOVUM and $TEF_IAAC must contain the path for those repositories'
  echo ''
  exit 1
fi

if [[ "$ASK_CONFIRMATION" == "yes" && -z "$DRY_RUN_OPTION" ]]; then
  read -p "You are going to perform an \"helm $HELM_ACTION\" operation in $NAMESPACE. Are you sure? [y/N] " OPT
  if [[ "$OPT" != "y" && "$OPT" != "Y" ]]; then
    echo "Aborted"
    exit 0
  fi
fi

kubeswitch tooling/pre
HELM_DRIVER=configmap helm -n $NAMESPACE $HELM_ACTION sentry-pre sentry $DRY_RUN_OPTION $DEBUG_OPTION -f "$TF_MODULE_KUBENOVUM/k8s-setup/chart-values/sentry.yaml" -f overrides/serviceaccount.yaml -f overrides/images.yaml -f overrides/sentry-pre-tooling-pre.yaml -f "$TEF_IAAC/environments/azure/northeurope09/prd.tooling/blue-k8s-infra/chart-values-override/sentry.yaml"
