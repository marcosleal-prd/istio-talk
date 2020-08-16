#!/bin/bash

# This script performs a GET request on a URL every .5 seconds.
# E.g: run.sh http://localhost:3000/health-check/
SLEEP_POD=$1

if [ -z "$SLEEP_POD" ]; then
    SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
fi;

while true; do
kubectl exec -it "$SLEEP_POD" -c sleep -- sh -c 'curl http://httpbin:8000/headers' | python -m json.tool
sleep .5;
done;
