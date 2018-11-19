# Steps using Databases for PostgreSQL on IBM Cloud as the database

Note: The Databases for PostgreSQL service on IBM Cloud is available through a pricing plan. Please see [Databases for PostgreSQL Catalog item](https://console.bluemix.net/catalog/services/databases-for-postgresql) for more details on pricing.

# Prerequisites

Create a Kubernetes cluster with [IBM Cloud Kubernetes Service](https://console.bluemix.net/docs/containers/cs_tutorials.html#cs_cluster_tutorial), folowing the steps to also configure the IBM Cloud CLI with the Kubernetes Service plug-in. 

# Steps

1. [Create Databases for PostgreSQL on IBM Cloud](#1-create-databases-for-postgresql-on-ibm-cloud)
2. [Create Services and Deployments](#2-create-services-and-deployments)
3. [Using Gitlab](#3-using-gitlab)

# 1. Create Databases for PostgreSQL on IBM Cloud

Use the IBM Cloud catalog or the `ibmcloud` command to create a service instance of `databases-for-postgresql-gl` and add a set of credentials.

```bash
$ibmcloud resource service-instance-create databases-for-postgresql-gl databases-for-postgresql standard <SERVICE_PLAN_NAME LOCATION>

$ibmcloud resource service-key-create --instance-name databases-for-postgresql-gl Credentials-1 Administrator
```
For example, in `us-south`: 
```$ ibmcloud resource service-instance-create databases-for-postgresql-gl databases-for-postgresql standard us-south```

Set the PostgreSQL database administrator password.

```bash
$ ibmcloud cdb user-password databases-for-postgresql-gl admin <admin_password>
```

Get the name of the target cluster and bind the credentials of the service instance to your kubernetes cluster.

```bash
$ ibmcloud cs clusters
$ ibmcloud cs cluster-service-bind --cluster <your cluster name> --namespace default --service databases-for-postgresql-gl
```

Verify that the credentials have been added.

```bash
$ kubectl get secrets
```

# 2. Create Services and Deployments

Run the following commands or run the quickstart script `bash scripts/quickstart-postgres-svc.sh` with your Kubernetes cluster.

```bash
$ kubectl create -f kubernetes/local-volumes.yaml
$ kubectl create -f kubernetes/redis.yaml
$ kubectl create -f kubernetes/gitlab-postgres-svc.yaml
```

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on the Kubernetes UI. Go to the cluster on the IBM Cloud and click on `Kubernetes Dashbaord` to check when the GitLab container becomes ready.

![Kubernetes Status Page](/images/kube_ui_gr.png)

After few minutes run the following commands to get your public IP and NodePort number.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.106   Ready     23h
$ kubectl get svc gitlab
NAME      CLUSTER-IP     EXTERNAL-IP   PORT(S)                     AGE
gitlab    10.10.10.148   <nodes>       80:30080/TCP,22:30022/TCP   2s
```

> Note: The `30080` port is for gitlab UI and the `30022` port is for ssh.

Congratulation. Now you can use the link **http://[IP]:30080** to access your gitlab site on browser.

> Note: For the above example, the link would be http://169.47.241.106:30080  since its IP is `169.47.241.106` and the UI port number is `30080`.

Depending on your cluster, the output might be as follows:

```bash
$ kubectl get nodes -o wide
NAME             STATUS    ROLES     AGE       VERSION       EXTERNAL-IP     OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
10.176.239.136   Ready     <none>    2d        v1.10.8+IKS   169.47.252.83   Ubuntu 16.04.5 LTS   4.4.0-137-generic   docker://17.6.2
10.176.239.146   Ready     <none>    2d        v1.10.8+IKS   169.47.252.51   Ubuntu 16.04.5 LTS   4.4.0-137-generic   docker://17.6.2
10.176.239.161   Ready     <none>    2d        v1.10.8+IKS   169.47.252.52   Ubuntu 16.04.5 LTS   4.4.0-137-generic   docker://17.6.2
$ kubectl get svc gitlab
NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                     AGE
gitlab    NodePort   172.21.170.161   <none>        80:30080/TCP,22:30022/TCP   2d
```

> Note: In this situation, you can use the external IP from any of the nodes. For the above example, the link can be http://169.47.252.51:30080  since an external IP is `169.47.252.51` and the UI port number is `30080`.

# 3. Using GitLab

Now that Gitlab is running you can register as a new user and create a project.

Firstly, you may need to create a password even before registering:

![Gitlab password page](/images/gitlab-passwd.png)

Then you can register a user:

![Registration page](/images/register.png)

After logging in as your newly-created user you can create a new project.

![Create project](/images/new_project.png)

Once a project has been created you'll be asked to add an SSH key for your user. You will also be provided with information on setting up your git global configuration which you should set on your environment.

To verify that your key is working correctly run:

```bash
$ ssh -T git@<IP> -p 30022
```

Which should result in:

```bash
Welcome to GitLab, <user>!
```
Now you can clone your project.
```bash
$ git clone ssh://git@<IP>:30022/<user>/<project name>
```

Add a file and commit:
```bash
$ echo "Gitlab project" > README.md
$ git add README.md
$ git commit -a -m "Initial commit"
$ git push origin master
```

You can now see it in the Gitlab UI.
![Repo](/images/first_commit.png)

If you want to use http URLs for cloning and pushing to a public repository on GitLab, that`s enabled as well.

# Troubleshooting

If a pod doesn't start examine the logs.
```bash
$ kubectl get pods
$ kubectl logs <pod name>
```

If you are getting the error `Permission denied (publickey).` when SSHing to GitLab and you have added the SSH key, then it might be related to a directory or file permission issue on the gitlab container. This can be due to an ownership problem of the `/var/opt/gitlab/` directory or the ` /var/opt/gitlab/.ssh/authorized_keys` file. Refer to the [stackoverflow question](https://stackoverflow.com/a/42474788) for more details.

To delete all your kubernetes services, deployments, and persistent volume claim, run

```bash
$ kubectl delete deployment,service,pvc -l app=gitlab
```

To delete your persistent volume, run

```bash
$ kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

To delete your PostgreSQL secret in kubernetes and remove the service instance from IBM Cloud, run

```bash
$ kubectl delete secret binding-databases-for-postgresql-gl
$ ibmcloud service key-delete "Databases for PostgreSQL-GL" Credentials-1
$ ibmcloud service delete "Databases for PostgreSQL-GL"
```

# License
[Apache 2.0](LICENSE)
