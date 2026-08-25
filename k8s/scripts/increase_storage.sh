#!/bin/sh
# Increase loghorn storage size dynamically
# Usage: ./increase_storage.sh <new_size>

if [ $# -ne 1 ]; then
    SIZE="1Gi"
else
    SIZE=""$1"Gi"
fi

kubectl patch pvc lubelogger-data -n lubelogger -p '{"spec":{"resources":{"requests":{"storage":"'$SIZE'"}}}}'
