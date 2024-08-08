#!/bin/bash

URL="https://localhost:10002/items"
CACERT="bundle.0.pem"
CERT="svid.0.pem"
KEY="svid.0.key"
NUM_REQUESTS=100

# Loop to make 100 requests
for ((i=1; i<=NUM_REQUESTS; i++))
do
  curl --cacert $CACERT --cert $CERT --key $KEY "$URL" -k
done
