# Build and push GitLab component images to the Bluemix Container Registry

*If you want to use the images directly from the docker hub you can skip this step.*

To ensure consistency you should always use tagged images from the docker registry. Taking this one step further you can push those images to your own namespace on the Bluemix Container Registry, or on [Docker Hub](https://docs.docker.com/datacenter/dtr/2.2/guides/user/manage-images/pull-and-push-images)

Install Docker CLI using the instructions found [here](https://www.docker.com/community-edition#/download).

Optionally, to use Bluemix Container Registry, install this plugin.

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

Fetch, tag, and push the GitLab container.

```bash
$ docker pull gitlab/gitlab-ce:9.1.0-ce.0
$ docker tag gitlab/gitlab-ce:9.1.0-ce.0 registry.ng.bluemix.net/<namespace>/gitlab-ce:9.1.0-ce.0
$ docker push registry.ng.bluemix.net/<namespace>/gitlab-ce:9.1.0-ce.0
```

Fetch, tag, and push the PostgreSQL container.

```bash
$ docker pull postgres:9.6.2-alpine
$ docker tag postgres:9.6.2-alpine registry.ng.bluemix.net/<namespace>/postgres:9.6.2-alpine
$ docker push registry.ng.bluemix.net/<namespace>/postgres:9.6.2-alpine
```

Fetch, tag, and push the Redis container.

```bash
$ docker pull redis:3.0.7-alpine
$ docker tag redis:3.0.7-alpine registry.ng.bluemix.net/<namespace>/redis:3.0.7-alpine
$ docker push registry.ng.bluemix.net/<namespace>/redis:3.0.7-alpine
```

After you finish building and pushing the images in registry, please modify the container images in `kubernetes/*.yaml` to match the new locations.

