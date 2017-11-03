# Deploy with IBM Cloud Private

Another option for getting a Kubernetes cluster up and running is to install IBM Cloud Private.

## Install IBM Cloud Private

Follow the directions at https://github.com/IBM/deploy-ibm-cloud-private to either install a local instance of IBM Cloud Private via Vagrant or a remote instance at Softlayer. Complete the optional step of adding an nfs-provisioner to the IBM Cloud Private installation to simplify set up of persistent volumes for the gitlab containers.

## Install Gitlab on the IBM Cloud Private cluster

1.  If you have not done so already, from a workstation install [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and then [configure for your ICP cluster](https://github.com/IBM/deploy-ibm-cloud-private#accessing-ibm-cloud-private)

2.  Install [Helm](https://github.com/kubernetes/helm) and then initialize:

    ```bash
    $ helm init --client-only
    ```

3.  Clone this repository to a local folder.

    ```bash
    git clone https://github.com/IBM/Kubernetes-container-service-GitLab-sample.git
    cd Kubernetes-container-service-GitLab-sample
    ```

4.  Install Gitlab using a helm chart included in this repository. If your Kubernetes cluster has a different dynamic provisioning [StorageClass](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#storageclasses) configured, replace the `nfs-dynamic` value with the name of that storage class.

    ```bash
    $ helm install --name gitlab --set baseDomain=example.com,gitlab=ce,legoEmail=fake@fake.com,provider=,gitlabConfigStorageClass=nfs-dynamic,gitlabDataStorageClass=nfs-dynamic,gitlabRegistryStorageClass=nfs-dynamic,postgresStorageClass=nfs-dynamic,redisStorageClass=nfs-dynamic,externalScheme=http charts/gitlab-omnibus
    ```

    > This chart is based off the beta [gitlab-omnibus](https://gitlab.com/charts/charts.gitlab.io/tree/master/charts/gitlab-omnibus) chart with some minor modifications to support use of storage classes and setting up a default http scheme for a quick startup without configuring CA-signed TLS certificates.

    The chart will deploy a gitlab installation that includes:

    *   A GitLab Omnibus Pod, including Mattermost, Container Registry, and Prometheus
    *   An auto-scaling GitLab Runner using the Kubernetes executor
    *   Redis
    *   PostgreSQL
    *   NGINX Ingress
    *   Persistent Volume Claims for Data, Registry, Postgres, and Redis

    Depending on the capabilities of the resources hosting the Gitlab cluster, startup time will be 8-15 minutes. You may check on status using the `kubectl get pods` command or the IBM Cloud Private dashboard.

5.  Once started, to access the gitlab Web UI, use the `kubectl` command to find the IP address of the ingress resource:

    ```bash
    $ kubectl get ingress
    NAME            HOSTS                                                                        ADDRESS        PORTS     AGE
    gitlab-gitlab   gitlab.example.com,registry.example.com,mattermost.example.com + 1 more...   169.45.74.56   80, 443   31s
    ```

6.  Update the workstation /etc/hosts file with an entry for gitlab.example.com with the address shown from the `kubectl get ingress command`:

    ```bash
    $ cat /etc/hosts
    127.0.0.1	localhost
    255.255.255.255	broadcasthost
    ::1             localhost

    169.45.74.56  gitlab.example.com registry.example.com mattermost.example.com
    ```

You can proceed to [test out Gitlab by adding a user and a repository](https://github.com/IBM/Kubernetes-container-service-GitLab-sample/blob/master/docs/using-gitlab.md). Note that this gitlab deployment does not expose access to port 22, so use the http protocol for cloning and working with repositories instead of ssh.

## Clean up

To uninstall the Gitlab chart

```bash
$ helm delete gitlab
```
