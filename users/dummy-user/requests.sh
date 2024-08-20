#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cert>"
    exit 1
fi

USER="$1"
URL="https://localhost:10002/items"
CACERT="bundle.$USER.pem"
CERT="svid.$USER.pem"
KEY="svid.$USER.key"
NUM_REQUESTS=10

# Loop to make requests
for ((i=1; i<=NUM_REQUESTS; i++))
do
  curl -s --cacert $CACERT --cert $CERT --key $KEY "$URL" -k >> /dev/null
done

echo "$NUM_REQUESTS requests done"
