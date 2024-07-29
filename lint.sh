#!/bin/sh

LINT_VARS=$(cat charts/sentry/lint-vars.txt)
sh -c "docker run -it --rm -v $(pwd):/charts -w /charts/charts docker.tuenti.io/sre/test-monkey:5.1.0 helm lint sentry $LINT_VARS"
