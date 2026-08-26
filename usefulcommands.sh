# get all pods addresses.
kubectl get pods -n lubelogger -o wide

# autoscaler log commands
kubectl -n lubelogger describe hpa keda-hpa-lubelogger-web


# Bench test commands
kubectl -n lubelogger port-forward svc/lubelogger 8080:80
watch -n 5 'kubectl -n lubelogger get hpa,scaledobject,pods; printf "\n"; kubectl top pods -n lubelogger'
ab -k -n 50000 -c 999 http://127.0.0.1:8080/Login
