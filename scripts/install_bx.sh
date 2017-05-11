#!/bin/bash

echo "Download Bluemix CLI"
wget --quiet --output-document=/tmp/Bluemix_CLI_amd64.tar.gz  http://public.dhe.ibm.com/cloud/bluemix/cli/bluemix-cli/latest/Bluemix_CLI_amd64.tar.gz
tar -xf /tmp/Bluemix_CLI_amd64.tar.gz --directory=/tmp

# Create bx alias
echo "#!/bin/sh" >/tmp/Bluemix_CLI/bin/bx
echo "/tmp/Bluemix_CLI/bin/bluemix \"\$@\" " >>/tmp/Bluemix_CLI/bin/bx
chmod +x /tmp/Bluemix_CLI/bin/*

export PATH="/tmp/Bluemix_CLI/bin:$PATH"

# Install Armada CS plugin
echo "Install the Bluemix container-service plugin"
bx plugin install container-service -r Bluemix

echo "Install kubectl"
wget --quiet --output-document=/tmp/Bluemix_CLI/bin/kubectl  https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x /tmp/Bluemix_CLI/bin/kubectl

if [ -n "$DEBUG" ]; then
  bx --version
  bx plugin list
fi

if [ -z $CF_ORG ]; then
  CF_ORG="$BLUEMIX_ORG"
fi
if [ -z $CF_SPACE ]; then
  CF_SPACE="$BLUEMIX_SPACE"
fi


if ([ -z "$BLUEMIX_USER" ] || [ -z "$BLUEMIX_PASSWORD" ] || [ -z "$BLUEMIX_ACCOUNT" ]) && ([ -z "$API_KEY"]); then
  echo "Define all required environment variables and rerun the stage."
  exit 1
fi

echo "Deploy pods"

echo "bx login -a $CF_TARGET_URL"

if [ -z "$API_KEY"]; then
  bx login -a "$CF_TARGET_URL" -u "$BLUEMIX_USER" -p "$BLUEMIX_PASSWORD" -c "$BLUEMIX_ACCOUNT" -o "$CF_ORG" -s "$CF_SPACE"
else
  bx login -a "$CF_TARGET_URL" --apikey "$API_KEY" -o "$CF_ORG" -s "$CF_SPACE"
fi

if [ $? -ne 0 ]; then
  echo "Failed to authenticate to Bluemix"
  exit 1
fi

# Init container clusters
echo "bx cs init"
bx cs init
if [ $? -ne 0 ]; then
  echo "Failed to initialize to Bluemix Container Service"
  exit 1
fi

#!/bin/bash

echo "Create Gitlab"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep Ready | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of Gitlab if it exists"
kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=gitlab
kubectl delete --ignore-not-found=true -f kubernetes/local-volumes.yaml

kuber=$(kubectl get pods -l app=gitlab)
if [ ${#kuber} -ne 0 ]; then
	sleep 30s
fi

echo -e "Creating pods"
kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/postgres.yaml
sleep 5s
kubectl create -f kubernetes/redis.yaml
sleep 5s
kubectl create -f kubernetes/gitlab.yaml
kubectl get nodes
kubectl get svc gitlab

echo "" && echo "View your Gitlab website at http://$IP_ADDR:30080"