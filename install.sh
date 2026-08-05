docker build -t ghcr.io/hargata/lubelogger:latest .
minikube image load ghcr.io/hargata/lubelogger:latest
kubectl rollout restart deployment/app
kubectl get pods
