#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR"

function usage() {
  echo "Usage: $(basename $0) [-h|--help][-a]"
  echo "List container images from sentry-pre chart from external registries"
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

./sentry-pre-template.sh | docker_image_importer list | grep -v dockerprx.prd.tooling.northeurope09.novumproject.com
