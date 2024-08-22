#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cert>"
    exit 1
fi

USER="$1"
url="https://localhost:10002/items"
certs_folders="$HOME/tcc/users/dummy-user/"
cacert="$certs_folders/bundle.$USER.pem"
cert="$certs_folders/svid.$USER.pem"
key="$certs_folders/svid.$USER.key"
num_requests=10

# Loop to make requests
for ((i=1; i<=num_requests; i++))
do
  curl -s --cacert $cacert --cert $cert --key $key "$url" -k >> /dev/null
done

echo "$num_requests requests done"
