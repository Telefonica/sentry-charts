#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

NAMESPACE=common

function usage() {
  echo "Usage: $(basename "$0") [-h] [-f] ENVIRONMENT"
  echo "Uninstall sentry from $NAMESPACE"
  echo ""
  echo "  -h  Show this help"
  echo "  -f  Full uninstall. Clean PersistentVolume, etc."
  echo "  ENVIRONMENT  Target environment (required)"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") common/dev        # Uninstall from common/dev"
  echo "  $(basename "$0") common/moves-pre  # Uninstall from common/moves-pre"
  echo "  $(basename "$0") -f common/moves-prd  # Full uninstall (including pvcs cleanup) in common/moves-prd"
  echo ""
}

KEEP_PV="yes"

while getopts "hf" OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    f)
      KEEP_PV="no"
      ;;
    *)
      echo "ERROR: Unknown option"
      echo ""
      usage
      exit 1
  esac
done
shift $((OPTIND-1))

# Check if environment parameter is provided
if [ $# -eq 0 ]; then
  echo "ERROR: Environment parameter is required"
  echo ""
  usage
  exit 1
fi

ENVIRONMENT="$1"
echo "Target environment: $ENVIRONMENT"

# Validate environment exists by trying to switch to it
if ! kubeswitch "$ENVIRONMENT" 2>/dev/null; then
  echo "ERROR: Environment '$ENVIRONMENT' not found or not accessible"
  echo "Please check if the environment exists and you have access to it"
  exit 1
fi

# Confirmation for non-dev environments
if [[ "$ENVIRONMENT" != *"/dev" ]]; then
  echo ""
  echo "⚠️  WARNING: You are about to uninstall Sentry from a NON-DEV environment: $ENVIRONMENT"
  echo ""
  read -p "Are you sure you want to continue? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Operation cancelled"
    exit 0
  fi
fi
helm -n $NAMESPACE uninstall sentry

kubectl -n $NAMESPACE delete deployment,job,sts -l 'app=sentry,release=sentry'
kubectl -n $NAMESPACE delete deployment,job,sts -l 'app.kubernetes.io/instance=sentry'


if [[ "$KEEP_PV" == "no" ]]; then
  # By design Helm doesn't delete PVCs, also some jobs may be left
  kubectl -n $NAMESPACE delete pvc -l 'app=sentry,release=sentry'
  kubectl -n $NAMESPACE delete pvc -l 'app.kubernetes.io/instance=sentry'
  kubectl -n $NAMESPACE get pv | grep $NAMESPACE/sentry-data | awk '{print $1}' | xargs kubectl -n $NAMESPACE delete pv
fi
