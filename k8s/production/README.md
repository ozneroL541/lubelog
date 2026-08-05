# Kubernetes Deployment

This directory is a production-oriented deployment for running `lubelogger` on Kubernetes with:

- `postgres` as a single-instance `StatefulSet`
- `lubelogger-web` as a scalable `Deployment`
- `lubelogger-events` as a single replica for background automation
- `ingress-nginx` in front of the app
- Longhorn-backed persistent storage

## Why it is split this way

- `postgres` stays single-writer and keeps its own `ReadWriteOnce` volume.
- `lubelogger-web` can scale horizontally because all replicas share:
  - `/App/data`
  - `/root/.aspnet/DataProtection-Keys`
- `lubelogger-events` prevents the scheduled background worker from running on every web pod.

## Prerequisites

1. A Kubernetes cluster with:
   - `kubectl`
   - `helm`
   - a working load balancer integration
   - a metrics pipeline for HPA, usually `metrics-server`
2. Longhorn installed and its `longhorn` `StorageClass` available.
3. NFS client packages installed on every node for Longhorn `ReadWriteMany` volumes.
   Longhorn RWX volumes depend on that shared volume path.
4. `ingress-nginx` installed.

## Bootstrap The Cluster Services

Install ingress-nginx:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.type=LoadBalancer
```

Install Longhorn:

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

## Required Edits Before Apply

Update these placeholders:

1. `02-postgres-secret.yaml`
   - change `POSTGRES_PASSWORD`
   - keep `POSTGRES_CONNECTION` in sync with the same password, username, and database
2. `03-bootstrap-auth-secret.yaml`
   - set a strong temporary bootstrap username and password
3. `01-configmap.yaml`
   - change `LUBELOGGER_DOMAIN` to the final public URL
4. `10-lubelogger-ingress.yaml`
   - change the host from `lubelog.example.com`
   - change the TLS secret name if needed
5. Optional:
   - pin the `ghcr.io/hargata/lubelogger` image to a released tag instead of `latest`
   - adjust storage sizes and resource requests

Create the namespace before creating the TLS secret:

```bash
kubectl apply -f k8s/production/00-namespace.yaml
```

If you are supplying your own certificate, create the TLS secret after the namespace exists:

```bash
kubectl -n lubelogger create secret tls lubelogger-tls --cert=/path/to/tls.crt --key=/path/to/tls.key
```

If you use cert-manager instead, replace the TLS handling in `10-lubelogger-ingress.yaml` with your issuer annotations and secret strategy.

## Deploy Everything

```bash
kubectl apply -k k8s/production
kubectl -n lubelogger rollout status statefulset/postgres
kubectl -n lubelogger rollout status deployment/lubelogger-web
kubectl -n lubelogger rollout status deployment/lubelogger-events
```

## First Login And Bootstrap Auth

This deployment starts with authentication enabled and registration disabled.

Use the credentials in `03-bootstrap-auth-secret.yaml` to sign in the first time.

After login:

1. Open `/setup`
2. Configure the app
3. Create permanent root credentials inside the application
4. Blank out `LUBELOGGER_BOOTSTRAP_USERNAME` and `LUBELOGGER_BOOTSTRAP_PASSWORD` in `03-bootstrap-auth-secret.yaml`
5. Reapply the kustomization so the bootstrap secret is no longer accepted

## Operational Notes

- Websocket support is disabled by default in `01-configmap.yaml`.
  This avoids cross-pod SignalR inconsistencies until a distributed backplane is added.
- The ingress still has sticky sessions and long timeouts in place, so enabling websocket support later is straightforward once a backplane exists.
- `nginx.ingress.kubernetes.io/proxy-body-size` is set to `512m` because the app accepts large uploads and the ingress default is too small.
- The HPA only targets `lubelogger-web`.
- The shared Longhorn volumes are what make horizontal scaling safe for uploaded files, config files, and ASP.NET Data Protection keys.

## Verification

Useful checks after rollout:

```bash
kubectl -n lubelogger get pods
kubectl -n lubelogger get pvc
kubectl -n ingress-nginx get svc
kubectl -n lubelogger describe ingress lubelogger
kubectl -n lubelogger get hpa
```
