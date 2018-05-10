# Steps using Compose for PostgreSQL on Bluemix as the database

Note: The Compose for PostgreSQL service on Bluemix is available through a pricing plan. Please see [Compose for PostgreSQL Catalog item](https://console.ng.bluemix.net/catalog/services/compose-for-postgresql/) for more details on pricing.


1. [Install Docker CLI and Bluemix Container registry Plugin](#1-install-docker-cli-and-bluemix-container-registry-plugin)
2. [Create Compose for PostgreSQL on Bluemix](#2-create-compose-for-postgresql-on-bluemix)
3. [Build Gitlab container](#3-build-gitlab-container)
4. [Create Services and Deployments](#4-create-services-and-deployments)
5. [Using Gitlab](#5-using-gitlab)

# 1. Install Docker CLI and Bluemix Container Registry Plugin


First, install [Docker CLI](https://www.docker.com/community-edition#/download).

Then, install the Bluemix container registry plugin.

```bash
bx plugin install container-registry -r bluemix
```

Once the plugin is installed you can log into the Bluemix Container Registry.

```bash
bx cr login
```

If this is the first time using the Bluemix Container Registry you must set a namespace which identifies your private Bluemix images registry. It can be between 4 and 30 characters.

```bash
bx cr namespace-add <namespace>
```

Verify that it works.

```bash
bx cr images
```

# 2. Create Compose for PostgreSQL on Bluemix

Use the Bluemix catalog or the `bx` command to create a service instance of Compose for PostgreSQL and add a set of credentials.

```bash
bx service create compose-for-postgresql Standard "Compose for PostgreSQL-GL"
bx service key-create "Compose for PostgreSQL-GL" Credentials-1
```

Get the name of the target cluster and bind the credentials of the service instance to your kubernetes cluster.

```bash
bx cs clusters
bx cs cluster-service-bind <your cluster name> default "Compose for PostgreSQL-GL"
```

Verify that the credentials have been added.

```bash
kubectl get secrets
```

# 3. Build GitLab container

A GitLab container needs to be built. The Redis container can be used as is from Docker Hub

Build the GitLab container.

```bash
cd containers/gitlab
docker build -t registry.ng.bluemix.net/<namespace>/gitlab .
docker push registry.ng.bluemix.net/<namespace>/gitlab
```

After finishing the image build in the bluemix registry, please modify the container image name in the yaml file.

i.e.
Replace `<namespace>` to your own container registry namespace. You can check your namespace via `bx cr namespaces`

# 4. Create Services and Deployments

Run the following commands or run the quickstart script `bash quickstart-postgres-svc.sh` with your Kubernetes cluster.

```bash
kubectl create -f local-volumes.yaml
kubectl create -f redis.yaml
kubectl create -f gitlab-postgres-svc.yaml
```

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on Kubernetes UI. Run `kubectl proxy` and go to URL 'http://127.0.0.1:8001/ui' to check when the GitLab container becomes ready.

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


# 5. Using GitLab
Now that Gitlab is running you can register as a new user and create a project.

![Registration page](/images/register.png)


After logging in as your newly-created user you can create a new project.

![Create project](/images/new_project.png)

Once a project has been created you'll be asked to add an SSH key for your user.

To verify that your key is working correctly run:

```bash
ssh -T git@<IP> -p 30022
```

Which should result in:

```bash
Welcome to GitLab, <user>!
```

Now you can clone your project.
```bash
git clone ssh://git@<IP>:30022/<user>/<project name>
```

Add a file and commit:
```bash
echo "Gitlab project" > README.md
git add README.md
git commit -a -m "Initial commit"
git push origin master
```

You can now see it in the Gitlab UI.
![Repo](/images/first_commit.png)

If you want to use http URLs for cloning and pushing to a public repository on GitLab, that`s enabled as well.

# Troubleshooting
If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```

To delete all your kubernetes services, deployments, and persistent volume claim, run

```bash
kubectl delete deployment,service,pvc -l app=gitlab
```

To delete your persistent volume, run

```bash
kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

To delete your PostgreSQL secret in kubernetes and remove the service instance from Bluemix, run

```bash
kubectl delete secret binding-compose-for-postgresql-gl
bx service key-delete "Compose for PostgreSQL-GL" Credentials-1
bx service delete "Compose for PostgreSQL-GL"
```

# License
[Apache 2.0](LICENSE)
