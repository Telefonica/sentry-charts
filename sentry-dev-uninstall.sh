#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

NAMESPACE=common

function usage() {
  echo "Usage: $(basename "$0") [-h][-u][-y][-d][-r]"
  echo "Uninstall sentry-dev from $NAMESPACE"
  echo ""
  echo "  -h  Show this help"
  echo "  -f  Full uninstall. Clean PersistentVolume, etc."
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

kubeswitch common/dev
helm -n $NAMESPACE uninstall sentry

kubectl -n $NAMESPACE delete deployment,job,sts -l 'app=sentry,release=sentry'
kubectl -n $NAMESPACE delete deployment,job,sts -l 'app.kubernetes.io/instance=sentry'


if [[ "$KEEP_PV" == "no" ]]; then
  # By design Helm doesn't delete PVCs, also some jobs may be left
  kubectl -n $NAMESPACE delete pvc -l 'app=sentry,release=sentry'
  kubectl -n $NAMESPACE delete pvc -l 'app.kubernetes.io/instance=sentry'
  kubectl -n $NAMESPACE get pv | grep $NAMESPACE/sentry-data | awk '{print $1}' | xargs kubectl -n $NAMESPACE delete pv
fi
