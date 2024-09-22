# quickube

> Instan Kubernetes clusters for prototypes, experimentation, development and testing.

## Getting started

### Install the CLI

> We will make this easier, do not fear.

1. Go to [releases](https://github.com/winglang/quickube/releases) and find the latest release.
2. Download the latest release to your box (since this is still a private GH repo, it's easiest to do it from the GitHub UI).
3. Install to 

```sh
$ curl -o qkube https://github.com/winglang/quickube/releases/download/v0.29.1/qkube-v0.29.1-macOS-ARM64
```

```console
$ curl https://get.quickube.sh | sh
qkube installed.
$ qkube --version
v0.34.0
```

### Login

```console
$ qkube login
<opens browser, GitHub/Google login/signup>
```

### Create a new cluster

```console
$ qkube new
Created cluster "fimble-shimble" of size medium (5000mcpu, 128GiB).
Using cluster "fimble-shimble" as your default kubectl context.
```

Now you can play with it:

```console
$ kubectl get all
...
```

You can also request a different size:

```console
$ qkube new --size small
Creating new cluster "dinker-pinker" of size small (1000mcpu, 64GiB)...
Using cluster "dinker-pinker" as your default kubectl context.
```

Other options:

```console
$ qkube new --region us-east-1 --size small
```

### List all my clusters

```console
$ qkube ls
  fimble-shimble medium
* dinker-pinker  small
  bangly-pangly  small
```

### Switch clusters

```console
$ qkube use bangly-pangly
Cluster "bangly-pangly" is now your default kubectl context.
```

### Delete a cluster

```console
$ qkube rm bangly-pangly
Cluster "bangly-pangly" is gone forever.
```

### Push an image to a cluster

```dockerfile
# Dockerfile
FROM hashicorp/http-echo
ENV ECHO_TEXT "Hello, quickube!"
```

```console
$ docker build -t dinker-pinker.quickube.sh/echo .
$ k8s registry password | docker login dinker-pinker.quickube.sh -u admin --password-stdin
$ docker push dinker-pinker.quickube.sh/echo
```

### Deploy a service with public access

```yaml
# manifest.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
        - name: echo
          image: dinker-pinker.quickube.sh/echo:latest
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: echo
spec:
  ports:
    - port: 5678
  selector:
    app: echo
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
spec:
  rules:
    - https:
        paths:
          - backend:
              service:
                name: echo
                port:
                  number: 5678
            path: /echo
            pathType: Prefix
```

And apply:

```console
$ kubectl apply -f manifest.yaml
```

And now it can be accessed from the internets *via HTTPS* :-):

```console
$ curl https://dinker-pinker.quickube.sh/echo
Hello, quickube!
```

### Collaboration

Create an invite URL for a cluster:

```console
$ qkube invite bangly-pangly
https://quickube.sh/join/bangly-pangly?key=xosdfkjsdf39dfjhsdf9l
```

Invitee clicks the link, logs in, and the cluster is added to their account.

Now, it's just there:

```sh
$ qkube use bangly-pangly
Using cluster "bangly-pangly" as your default kubectl context.
```

## API

### Create a new cluster

```
POST /clusters
```

Request body:

```json
{
  "size": "small" | "medium" | "large" | "xlarge",
  "region": "<provider-dependent>",
  "provider": "aws" | "azure" | "gcp"
}
```

Response:

```json
{
  "name": "bangly-pangly",
  "size": "small" | "medium" | "large" | "xlarge",
  "region": "<provider-dependent>",
  "provider": "aws" | "azure" | "gcp"
}
```

### Use cluster

```
GET /clusters/:name/creds
```

Response:

```json
{
  "publicIp": "1.2.3.4",
  "size": "medium",
  "region": "us-east-1",
  "provider": "aws",
  "kubeconfig": "<kubeconfig...>",
  "registryPassword": "x2923847usdcbjs8kjsdfsdf"
}
```

### List clusters

```
GET /clusters
```

Response:

```json
{
  "clusters": [
    {
      "name": "bangly-pangly",
      "size": "small" | "medium" | "large" | "xlarge",
      "region": "<provider-dependent>",
      "provider": "aws" | "azure" | "gcp"
    }
  ]
}
```

### Delete a cluster

```
DELETE /clusters/:name
```

### Create an invite link

```
POST /clusters/:name/invites
```

Response:

```json
{
  "invite": "https://quickube.sh/join/bangly-pangly?key=xosdfkjsdf39dfjhsdf9l"
}
```

## Development

### Launching a single instance for tests

```sh
cd scripts/launch-instance
./launch.sh
```

(you'll need AWS creds in your environment)

## Roadmap

* IP allow list, in customer VPC
* Custom domain names (e.g. bangly-pangly.acme.com)
* Cluster templates (e.g. preloaded secrets, services, argo, etc)
* Self-hosted in customer account and managed by us
* Remote debugging with hot reloading
* Auto-create for pull requests (preview environments)
* RBAC
