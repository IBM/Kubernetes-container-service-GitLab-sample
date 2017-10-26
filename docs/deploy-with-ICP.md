# Deploy with IBM Cloud Private

Another option for getting a Kubernetes cluster up and running is to install
IBM Cloud Private.

Follow the directions at https://github.com/IBM/deploy-ibm-cloud-private to
either install a local instance of IBM Cloud Private via Vagrant or a remote
instance at Softlayer.  These instructions assume the former.

Log into the Vagrant VM

```bash
$ vagrant ssh
```

Start helm and add the repository

```bash
$ helm init
$ helm repo add gitlab https://charts.gitlab.io
```

Install Gitlab

```bash
$ helm install --name gitlab --set baseDomain=example.com,baseIP=1.1.1.1,gitlab=ce,legoEmail=fake@fake.com gitlab/gitlab-omnibus
```

This will deploy a gitlab installation that includes:

    A GitLab Omnibus Pod, including Mattermost, Container Registry, and Prometheus
    An auto-scaling GitLab Runner using the Kubernetes executor
    Redis
    PostgreSQL
    NGINX Ingress
    Persistent Volume Claims for Data, Registry, Postgres, and Redis

To access the web UI, first navigate to the list of applications
(nav menu -> workloads -> applications) and select the "default-http-backend"
application that is under the  nginx-ingress namespace by clicking on its name.
Scroll down to the Expose Details section - listed under Endpoint is a link to
"access 80" - click on it to interact with gitlab through its UI (once it has
had a chance to spin up).

# Clean up

To uninstall the Gitlab Chart

```bash
$ helm delete gitlab
```
