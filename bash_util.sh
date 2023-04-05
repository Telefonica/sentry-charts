#!/bin/bash

# File only to be included by scripts

function is_valid_repo() {
  local REPO_PATH="$1"
  local FILE_TO_CHECK="$2"

  if [[ -d "$REPO_PATH" && -f "$REPO_PATH/$FILE_TO_CHECK" ]]; then
    return 0
  fi

  return 1
}

# find_and_validate_external_repositories()
# This function checks the values for current TF_MODULE_KUBENOVUM and TEF_IAAC, set them to default
# values if they are missing, and check that the repositories are valid.
#
# Input:
# SCRIPT_DIR          = Path of the running script
# TEF_IAAC            = Path of the tef_iaac repository or empty to use the default one
# TF_MODULE_KUBENOVUM = Path of the tf_module_kubenovum repository or empty to use the default one
#
# Output
# TEF_IAAC            = Clean path of the tef_iaac repository
# TF_MODULE_KUBENOVUM = Clean path of the tf_module_kubenovum repository
#
# If one of the paths is invalid, the script will exit
function find_and_validate_external_repositories() {
  # Find/check the other required repositories
  DEFAULT_TF_MODULE_KUBENOVUM="$SCRIPT_DIR/../tf-module-kubenovum"
  FILE_TO_CHECK_TF_MODULE_KUBENOVUM="k8s-setup/chart-sentry.tf"
  DEFAULT_TEF_IAAC="$SCRIPT_DIR/../tef-iaac"
  FILE_TO_CHECK_TEF_IAAC="environments/azure/northeurope09/prd.tooling/blue-k8s-infra/chart-values-override/sentry.yaml"

  TF_MODULE_KUBENOVUM="${TF_MODULE_KUBENOVUM:-$DEFAULT_TF_MODULE_KUBENOVUM}"
  if ! is_valid_repo "$TF_MODULE_KUBENOVUM" "$FILE_TO_CHECK_TF_MODULE_KUBENOVUM"; then
    echo "ERROR: \"$TF_MODULE_KUBENOVUM\" is not a valid tf_module_kubenovum repository. Specify the correct path with -k PATH."
    echo ""
    exit 1
  fi

  # Simplifies the path, removing .., etc.
  TF_MODULE_KUBENOVUM="$(cd $TF_MODULE_KUBENOVUM; pwd -P)"

  TEF_IAAC="${TEF_IAAC:-$DEFAULT_TEF_IAAC}"
  if ! is_valid_repo "$TEF_IAAC" "$FILE_TO_CHECK_TEF_IAAC"; then
    echo "ERROR: \"$TEF_IAAC\" is not a valid tef_iaac repository. Specify the correct path with -t PATH."
    echo ""
    exit 1
  fi

  # Simplifies the path, removing .., etc.
  TEF_IAAC="$(cd $TEF_IAAC; pwd -P)"
}
