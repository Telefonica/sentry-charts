#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

source ./bash_util.sh

function usage() {
  echo "Usage: $(basename "$0") [-h][-a][-k PATH][-t PATH]"
  echo "List container images from sentry-pre chart from external registries"
  echo ""
  echo "  -h         Show this help"
  echo "  -a         List all images, not only the external ones"
  echo "  -k PATH    tf_module_kubenovum repository path. If not present it will try to look for it in the parent dir"
  echo "  -t PATH    tef_iaac repository path. If not present it will try to look for it in the parent dir"
  echo ""
}

TF_MODULE_KUBENOVUM=
TEF_IAAC=
declare -a OPTION_TF_MODULE_KUBENOVUM
declare -a OPTION_TEF_IAAC
LIST_ALL="no"

while getopts "ahk:t:" OPT; do
  case "$OPT" in
    h)
      usage
      exit 0
      ;;
    a)
      LIST_ALL="yes"
      ;;
    k)
      TF_MODULE_KUBENOVUM="$OPTARG"
      OPTION_TF_MODULE_KUBENOVUM=("-k" "$TF_MODULE_KUBENOVUM")
      ;;
    t)
      TEF_IAAC="$OPTARG"
      OPTION_TEF_IAAC=("-t" "$TEF_IAAC")
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

FILTER="grep -v dockerprx.prd.tooling.northeurope09.novumproject.com"
if [[ "$LIST_ALL" == "yes" ]]; then
  FILTER="cat"
fi

./sentry-pre-template.sh "${OPTION_TEF_IAAC[@]}" "${OPTION_TF_MODULE_KUBENOVUM[@]}" 2>/dev/null | grep -o '^\s*image:.*' | sed -e 's/^\s*image:\s*//' -e 's/^"//' -e 's/"$//' | sort | $FILTER
