#!/bin/bash

# Since we got fed up with debugging and the fact that the StatefulSet always re-instantiate all pods even after deletion,
# this should serve as a good script to make sure everything is dead to the reload everything for testing purposes

# Erase LubeLogger
kubectl delete all --all -n lubelogger
kubectl delete configmap --all -n lubelogger
kubectl delete secret --all -n lubelogger
kubectl delete ingress --all -n lubelogger
# Erase Longhorn
kubectl delete all --all -n longhorn-system
kubectl delete pvc --all --all-namespaces
kubectl delete pv --all
kubectl delete configmap --all -n longhorn-system
kubectl delete secret --all -n longhorn-system
kubectl delete ingress --all -n longhorn-system
# Erase KEDA
kubectl delete all --all -n keda
# Erase Kata
kubectl delete all --all -n default 

kubectl -n lubelogger delete hpa lubelogger-web
kubectl -n lubelogger delete deployment lubelogger-web lubelogger-events
kubectl -n lubelogger delete statefulset postgres
kubectl -n lubelogger delete ingress lubelogger
kubectl -n lubelogger delete svc lubelogger postgres
kubectl -n lubelogger delete pdb lubelogger-web
kubectl -n lubelogger delete scaledobject lubelogger-web

kubectl delete namespace lubelogger

kubectl -n longhorn-system get volumes.longhorn.io

kubectl delete --server-side -f https://github.com/kedacore/keda/releases/download/v2.20.0/keda-2.20.0-core.yaml
kubectl delete namespace keda


# If KEDA does not behave:
# kubectl delete apiservice v1beta1.external.metrics.k8s.io
# Watch KEDA get terminated 
# kubectl get ns keda -w
# kubectl patch namespace keda --type=merge -p '{"spec":{"finalizers":[]}}'