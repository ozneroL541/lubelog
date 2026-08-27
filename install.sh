#!/bin/bash
set -euo pipefail
### Variables ###
# K8s Node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
# K8s type
KUBELET_VERSION=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}')
case "$KUBELET_VERSION" in
    *+k3s*)  K8s_TYPE="k3s"  ;;
    *+rke2*) K8s_TYPE="rke2" ;;
    *+k0s*)  K8s_TYPE="k0s"  ;;
    *)       K8s_TYPE="k8s"  ;;   # kubeadm, minikube, kind, EKS, GKE, AKS, etc.
esac
### Secrets ###
# Generate the keys for sops
bash k8s/scripts/sops_setup.sh
# Encrypt everything with the installed secret
#bash k8s/scripts/encrypt_secrets.sh
# Apply the secrets to the cluster
bash k8s/scripts/apply_secret.sh
### Firewall ###
# Allow forwarding across CNI interfaces
if which iptables >/dev/null 2>&1; then
    sudo iptables -P FORWARD ACCEPT
fi
### KATA ###
# Install Kata with helm
KATA_VERSION=$(curl -sSL https://api.github.com/repos/kata-containers/kata-containers/releases/latest | jq -r .tag_name)
KATA_CHART="oci://ghcr.io/kata-containers/kata-deploy-charts/kata-deploy"
helm install kata-deploy "${KATA_CHART}" --version "${KATA_VERSION}"
# Fix according to K8s type
helm upgrade kata-deploy $KATA_CHART -n default --set k8sDistribution="${K8s_TYPE}"
# Check for Kata availability
if ! kubectl get runtimeclass kata-qemu-runtime-rs >/dev/null 2>&1; then
    echo "Kata runtime class not found. Please ensure Kata Containers is installed and the runtime class is available."
    exit 1
fi
# Accept Kata
kubectl label node $NODE_NAME kata-deploy.katacontainers.io/default=true katacontainers.io/kata-runtime=true --overwrite
### Longhorn ###
# Install longhorn for dynamic storage provisioning
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.12.1/deploy/longhorn.yaml
### Docker ###
# If docker image does not exist, build it
if ! docker image inspect lubelogger:k8s-1 >/dev/null 2>&1; then
    docker build -t "lubelogger:k8s-1" .
fi
docker save "lubelogger:k8s-1" | sudo k3s ctr -n k8s.io images import -
### K8s ###
kubectl apply -k k8s/production
kubectl -n lubelogger set image deployment/lubelogger-web lubelogger=lubelogger:k8s-1
kubectl -n lubelogger set image deployment/lubelogger-events lubelogger-events=lubelogger:k8s-1

# kubectl -n lubelogger rollout status statefulset/postgres
# kubectl -n lubelogger rollout status deployment/lubelogger-web
# kubectl -n lubelogger rollout status deployment/lubelogger-events
# kubectl -n lubelogger get pods
# kubectl -n lubelogger get pvc
# kubectl -n lubelogger get ingress
# kubectl -n lubelogger get hpa
