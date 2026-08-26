# docker build -t ghcr.io/hargata/lubelogger:latest .
# minikube image load ghcr.io/hargata/lubelogger:latest
# kubectl rollout restart deployment/app
# kubectl get pods

# Commands to build the custom image
# docker build -t "lubelogger:k8s-1" .
# sudo k3s ctr -n k8s.io images import -
# sudo k3s ctr -n k8s.io images list | grep lubelogger

# spec:
#   template:
#     spec:
#       containers:
#         - name: app
#           image: ghcr.io/hargata/lubelogger:latest
#           imagePullPolicy: IfNotPresent

# TODO: I've added all the lines just to keep them somewhere. They need to be removed at some point. 

# TODO: change password for the database which now its stupid just to test it.

# HACK: fs inotify system does not make autoscaling work that much because at a certain point KEDA tries to scale up,
# but the app throws an exception and nothing works. So this is to reduce that behaviour.
sudo sysctl -w fs.inotify.max_user_instances=1024
sudo sysctl -w fs.inotify.max_user_watches=524288
sudo sysctl -w fs.inotify.max_queued_events=16384
sudo sysctl --system


kubectl apply -f "./k8s/production/00-namespace.yaml"

# Generate the keys for sops
bash k8s/scripts/sops_setup.sh
# Encrypt everything with the installed secret
#bash k8s/scripts/encrypt_secrets.sh
# Apply the secrets to the cluster
bash k8s/scripts/apply_secret.sh
# Allow forwarding across CNI interfaces
if which iptables >/dev/null 2>&1; then
    sudo iptables -P FORWARD ACCEPT
fi

# Install KEDA for K8S autoscaling
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.20.0/keda-2.20.0.yaml

# Install longhorn for dynamic storage provisioning
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.12.0/deploy/longhorn.yaml
docker build -t "lubelogger:k8s-1" .
docker save "lubelogger:k8s-1" | sudo k3s ctr -n k8s.io images import -
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
