#!/bin/bash

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo -e "\033[0;33mPull Request detected; not installing extra software.\033[0m"
    exit 0
fi

echo "Install Bluemix CLI"
curl -L https://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/latest/Bluemix_CLI_amd64.tar.gz > Bluemix_CLI.tar.gz
tar -xvf Bluemix_CLI.tar.gz
sudo ./Bluemix_CLI/install_bluemix_cli

echo "Install kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl
chmod 0755 kubectl
sudo mv kubectl /usr/local/bin

echo "Install the Bluemix container-service plugin"
bx plugin install container-service -r Bluemix

if [[ -n "$DEBUG" ]]; then
  bx --version
  bx plugin list
fi
