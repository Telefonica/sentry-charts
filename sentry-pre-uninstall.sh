#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

NAMESPACE=tooling-pre

function usage() {
  echo "Usage: $(basename "$0") [-h][-u][-y][-d][-r]"
  echo "Uninstall sentry-pre from $NAMESPACE"
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

kubeswitch tooling/pre
HELM_DRIVER=configmap helm -n $NAMESPACE uninstall sentry-pre

kubectl -n $NAMESPACE delete deployment,job,sts -l 'app in (sentry, sentry-pre),release=sentry-pre'
kubectl -n $NAMESPACE delete deployment,job,sts -l 'app.kubernetes.io/instance=sentry-pre'


if [[ "$KEEP_PV" == "no" ]]; then
  # By design Helm doesn't delete PVCs, also some jobs may be left
  kubectl -n $NAMESPACE delete pvc -l 'app in (sentry, sentry-pre),release=sentry-pre'
  kubectl -n $NAMESPACE delete pvc -l 'app.kubernetes.io/instance=sentry-pre'
  kubectl -n $NAMESPACE get pv | grep $NAMESPACE/sentry-pre-data | awk '{print $1}' | xargs kubectl -n $NAMESPACE delete pv
fi

if kubectl -n common get pods -l'kraken/service=sentry-multiplexer' | grep sentry-multiplexer >/dev/null ; then
  echo ""
  echo "If you are using sentry-multiplexer you may want to disable it after this. Read Sentry doc for more information."
  echo ""
fi
