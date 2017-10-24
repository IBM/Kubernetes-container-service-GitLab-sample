#!/bin/bash -e

# This script is intended to be run by Travis CI. If running elsewhere, invoke
# it with: TRAVIS_PULL_REQUEST=false [path to script]
# If no credentials are provided at runtime, bx will use the environment
# variable BLUEMIX_API_KEY. If no API key is set, it will prompt for
# credentials.

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

BLUEMIX_ORG="Developer Advocacy"
BLUEMIX_SPACE="dev"

is_pull_request "$0"

echo "Authenticating to Bluemix"
bx login -a https://api.ng.bluemix.net

echo "Targeting Bluemix org and space"
bx target -o "$BLUEMIX_ORG" -s "$BLUEMIX_SPACE"

echo "Initializing Bluemix Container Service"
bx cs init
