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

# Generate the keys for sops
bash k8s/scripts/sops_setup.sh
# Encrypt everything with the installed secret
bash k8s/scripts/encrypt_secrets.sh

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
