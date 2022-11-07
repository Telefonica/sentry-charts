#!/bin/sh

LINT_VARS=$(cat sentry/lint-vars.txt)
sh -c "docker run -it --rm -v $(pwd):/charts -w /charts docker.tuenti.io/sre/test-monkey:3.0.0 helm lint sentry $LINT_VARS"
