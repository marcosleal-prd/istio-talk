#!/bin/bash

# This script performs a GET request on a URL every .5 seconds.
# E.g: run.sh http://localhost:3000/health-check/
URL=$1

if [ -z "$URL" ]; then
    URL="http://127.0.0.1/productpage"
fi;

# Run with siege:
# while true; do siege -c 1 -r 1 $URL

# Run with watch:
# watch -n 1 curl -o /dev/null -s -w "%{http_code} - GET $URL\n" $URL
while true; do
curl -o /dev/null -s -w "%{http_code} - GET $URL\n" $URL;
sleep .5;
done;
