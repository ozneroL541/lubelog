There are 5 separate layers:
1. Your source code on disk
2. A Docker image built from that code
3. Minikube’s internal image store
4. A Kubernetes Deployment that says which image to run
5. A running Pod created from that deployment
The flow is:
source code
  -> docker build
image on your PC
  -> minikube image load
image inside Minikube
  -> kubectl set image / kubectl apply
deployment spec updated
  -> rollout
new pod starts
  -> port-forward / service / ingress
you can test it
What Happened In Your Case
1. You built the fixed app image locally:
docker build -t "iHateKubernetes/lubelogger:k8s-1" .
Plan·GPT-5.4OpenAI·xhigh
2. You added a simpler local tag:
docker tag "iHateKubernetes/lubelogger:k8s-1" "lubelogger:k8s-1"
3. Minikube already had that image in its own image store:
minikube image ls | grep lubelogger
It showed:
docker.io/library/lubelogger:k8s-1
4. The existing Kubernetes deployment was still using the old upstream image:
ghcr.io/hargata/lubelogger:latest
5. You changed the deployment to use your Minikube-loaded image:
kubectl -n default set image deployment/app app=lubelogger:k8s-1
6. Kubernetes created a new ReplicaSet and then a new Pod.
7. The old pod stayed around briefly during rolling update, which is normal.
8. The new pod reported:
lubelogger:k8s-1
9. You tested the health endpoints and got a healthy result.
That means the custom image is really running in Minikube now.
Why Loaded Is Not The Same As Running
These are different states:
1. docker build
- creates an image on your host machine only
2. minikube image load
- copies that image into Minikube’s runtime
- this still does not start any pods
3. kubectl set image or kubectl apply
- tells Kubernetes to use that image
4. Rollout
- Kubernetes creates a new pod from that image
So this is the key rule:
Image present in Minikube != deployment is using it
What Each Command Actually Does
docker build -t "lubelogger:k8s-1" .
- Reads Dockerfile
- Builds the container image on your machine
- Stores it in your host Docker image list
docker tag "oldname" "lubelogger:k8s-1"
- Adds another name to the exact same image
- No rebuild happens
minikube image build -t "lubelogger:k8s-1" .
- Builds the image inside Minikube, not on your host
- That failed for you because Minikube itself could not reach mcr.microsoft.com
minikube image load "lubelogger:k8s-1"
- Copies an already built host image into Minikube
- This is usually the safer local dev path
minikube image ls
- Shows images known inside the Minikube node
kubectl set image deployment/app app=lubelogger:k8s-1
- Edits the deployment spec in the cluster
- deployment/app is the deployment name
- app= is the container name inside that deployment
- lubelogger:k8s-1 is the image Kubernetes should use now
kubectl rollout status deployment/app
- Waits for the new pod to become ready
- Shows whether the update finished
kubectl get deployment ... -o jsonpath=...
- Shows the image Kubernetes wants to run
kubectl get pod ... -o jsonpath=...
- Shows what image a running pod is actually using
kubectl port-forward deployment/app 8080:8080
- Opens a tunnel from your PC to one pod in that deployment
- Useful when service/ingress is not ready yet
curl http://localhost:8080/healthz/live
- Checks whether the app process is up
curl http://localhost:8080/healthz/ready
- Checks whether the app is ready to serve traffic
- In your code, this readiness check also verifies storage and Postgres if configured
Why minikube image build Failed But docker build Worked
Because they use different networks.
docker build
- runs with your host Docker environment
- your host could reach the .NET base images
minikube image build
- runs inside the Minikube node/container
- Minikube could not reach mcr.microsoft.com
- so it timed out before it could pull the base images
That is why the reliable local workflow is often:
docker build
-> minikube image load
-> kubectl set image / kubectl apply
Why The Service Was Broken
Your currently running quick test is using the old default/app deployment and service.
The service had no endpoints because:
1. The service selector did not match the pod labels
2. So Kubernetes had no pod to attach to that service
You saw:
kubectl -n default get endpoints app
app    <none>
That means:
- the deployment existed
- the pod existed
- but the service was not pointing at it
That is why port-forward deployment/app worked better than using the service.
Why You Saw Two Pods During Rollout
When you changed the image:
kubectl -n default set image deployment/app app=lubelogger:k8s-1
Kubernetes did this:
1. Created a new ReplicaSet with the new pod template
2. Started a new pod with your image
3. Waited for it to become ready
4. Terminated the old pod
That is why you saw:
- old pod on ghcr.io/hargata/lubelogger:latest
- new pod on lubelogger:k8s-1
That is normal rolling update behavior.
What Your Health Check Result Means
When you got Healthy, it proved:
1. The app process started
2. The pod was serving HTTP
3. The readiness check passed
4. Your custom image was valid enough to run in Minikube
It does not yet prove:
1. Your real Postgres layout works
2. Your production PVC layout works
3. Your ingress works
4. The web/events split works
5. Your final manifests are correct
It only proves the image and app boot path are okay.
The Current Test You Ran vs The Real Deployment
Right now you are doing a smoke test on an existing deployment in the default namespace.
That is different from the real design we planned.
Current smoke test:
- namespace: default
- deployment: app
- replicas: 1
- no proper Postgres setup
- broken service selector
- no lubelogger namespace
- no web vs events split
- no Longhorn layout
Real target deployment:
- namespace: lubelogger
- single Postgres StatefulSet
- scalable lubelogger-web deployment
- single lubelogger-events deployment
- PVCs for data and keys
- ingress
- HPA
So your current test is useful, but only as a first layer of verification.
How To Think About Names
These names are easy to mix up:
image tag
- lubelogger:k8s-1
- just a label for the image
deployment name
- app
- Kubernetes object controlling pods
container name
- app
- name of the container inside the deployment
- used by kubectl set image
namespace
- default
- logical grouping of resources
pod name
- app-9f47546b9-fwh44
- generated runtime object
The Most Important Checks
When debugging, always check these 4:
1. Is the image built on the host?
docker images | grep lubelogger
2. Is the image loaded into Minikube?
minikube image ls | grep lubelogger
3. What image does the deployment want?
kubectl -n default get deployment app -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
4. What image is the running pod actually using?
kubectl -n default get pod -l app=lubelogger -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{range .status.containerStatuses[*]}{.image}{" | "}{.imageID}{"\n"}{end}{end}'
If all 4 line up, your image path is correct.
The Right Script Structure
For a local Minikube smoke-test script, the phases should be:
1. Check prerequisites
2. Build image locally
3. Tag image consistently
4. Load image into Minikube
5. Update deployment image
6. Wait for rollout
7. Verify pod image
8. Port-forward
9. Run health checks
A clean shell-script shape looks like this:
#!/usr/bin/env bash
set -euo pipefail

IMAGE="lubelogger:k8s-1"
DEPLOYMENT="app"
CONTAINER="app"
NAMESPACE="default"

minikube status
kubectl config current-context

docker build -t "$IMAGE" .
minikube image load "$IMAGE"

kubectl -n "$NAMESPACE" set image deployment/"$DEPLOYMENT" "$CONTAINER"="$IMAGE"
kubectl -n "$NAMESPACE" rollout status deployment/"$DEPLOYMENT"

kubectl -n "$NAMESPACE" get deployment "$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
kubectl -n "$NAMESPACE" get pod -l app=lubelogger -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{range .status.containerStatuses[*]}{.image}{" | "}{.imageID}{"\n"}{end}{end}'

kubectl -n "$NAMESPACE" port-forward deployment/"$DEPLOYMENT" 8080:8080
Then in another terminal:
curl -f http://127.0.0.1:8080/healthz/live
curl -f http://127.0.0.1:8080/healthz/ready
Rules For Local Minikube Testing
1. Prefer docker build + minikube image load
- more reliable than minikube image build
2. Use imagePullPolicy: IfNotPresent
- this lets Kubernetes use the image already loaded into Minikube
- Always is a bad fit for local-only images
3. Keep image tags consistent
- build tag
- loaded tag
- deployment tag
- all must match
4. Use port-forward first
- it removes service and ingress from the problem
- good for first-pass debugging
5. Do not confuse default/app smoke test with your real stack
- they are different things
What Changes Later For Production
In production, minikube image load disappears.
The flow becomes:
docker build
-> push to registry
-> kubectl apply manifests that reference registry image
-> cluster pulls image itself
So your eventual production script will replace:
minikube image load "$IMAGE"
with something like:
docker push registry.example.com/lubelogger:k8s-1
kubectl apply -k ...
If You Want To Script The Real Minikube Stack Later
The script will need 2 modes:
1. smoke-test
- use existing default/app
- fastest feedback
- validates image boots
2. full-minikube-stack
- create lubelogger namespace
- apply Minikube-friendly manifests
- use local storage instead of Longhorn assumptions
- deploy Postgres + web + events
- port-forward service
- validate health
That split will save you a lot of pain.
Bottom Line
What made it work was exactly this:
1. build image locally
2. load image into Minikube
3. point deployment at that exact image
4. wait for rollout
5. test via port-forward and health endpoints
That is the core logic your script needs to automate.
If you want, next I can help you design the script in two explicit stages:
1. local smoke test
2. real Minikube deployment from manifests