# DevSecOps Homework Problem

## Technical requirements
- [`helm`](https://helm.sh/docs/intro/install/) 
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- A local kubernetes cluster (kind, k3d, docker desktop etc)
- `make`

Stand up your own local kubernetes cluster for development - you do not need to stand up a cluster in the Makefile.

# Homework problem

## Step 1 - Deploy podinfo

The first step will be to create a values file and Makefile target to deploy [podinfo](https://github.com/stefanprodan/podinfo) to the `podinfo` namespace.

Modify the `deploy_podinfo` Makefile target to deploy
the helm chart to the `podinfo` namespace (Note, this will run in CI so don't forget to add the helm repo in your target)

## Step 2 - Update the podinfo deployment

Now that podinfo is deployed, you realize that you probably need 3 pods to manage all the traffic to your beautiful podinfo deployment.

Additionally, you're conflicted with another deployment ingressing on 9898.  Create a values file to configure the following:
- 3 pods
- HTTP port on 5050 (including service port)

Create a script to do a rolling update to the deployment by modifying the `udpate_podinfo` target in the Makefile.

## Step 3 - Integrate a backend service

The final step well be to integrate a backend service that returns a simple message:
```json
{"message": "hello world",
"service": "nginx"}
```

You should deploy an nginx deployment and service into the `nginx` namespace. Do this by creating a `configmap.yaml`, `deployment.yaml`, and `service.yaml` manifest in the `manifests/` folder.

**Requirements:**
- Use `nginx:1.27-alpine` as the image
- Name the deployment `nginx`
- Name the service `nginx` (ClusterIP, port 80)
- Configure the deployment to respond with the above JSON message from the root url (`/`)

Next, use podinfo's backend capability (see https://github.com/stefanprodan/podinfo/tree/master/charts/podinfo for details) to integrate with the nginx deployment - use the nginx internal DNS url.

Finally, modify the `deploy_backend` Makefile target to:
- deploy `nginx`
- deploy `podinfo`
- test the `/echo` endpoint returns the appropriate message
