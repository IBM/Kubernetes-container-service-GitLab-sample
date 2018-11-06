# Expose SSH Port with Ingress Controller in IKS

1. Edit configmap for ALB (Application Load Balancer)

```
$ kubectl edit configmap ibm-cloud-provider-ingress-cm -n kube-system
```

Add port `22` in the public ports:

```
...
data:
  public-ports: 80;443;22
...
```

2. Edit Ingress of GitLab

```
$ kubectl edit ingress gitlab-unicorn
```

Add this in one of the annotations:

```
...
annotations:
  ingress.bluemix.net/tcp-ports: "serviceName=gitlab-gitlab-shell ingressPort=22"
...
```

3. Verify

First, verify if the ALB is exposing the `22` port.

```
$ kubectl get service -n kube-system

NAME                                             TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)                                   AGE
...
public-cr486e6497c6da4d5ca3b15edb99e216fe-alb1   LoadBalancer   172.21.130.120   169.XX.XX.XX   80:31256/TCP,443:32340/TCP,22:30917/TCP   47d                        4d
```

Next, verify if you can ssh with the ingress subdomain _(Assuming you already have registered and added an SSH key in your GitLab deployment)_:
> Use your own Ingress Subdomain `gitlab.<INGRESS_SUBDOMAIN>`

```
$ ssh -T git@gitlab.anthony-dev.us-south.containers.appdomain.cloud

Welcome to GitLab, @anthony!
```