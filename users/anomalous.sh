#!/bin/bash

HOST="https://localhost:10002"
URI="/items"
USER="2"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$certs_folders/bundle.$USER.pem"
CERT="$certs_folders/svid.$USER.pem"
KEY="$certs_folders/svid.$USER.key"

function get_anomalous_interval {
  local interval=$RANDOM
  if (( interval % 2 )); then
    echo $(( inteval % 10 + 1 ))  # 1 a 10 seconds
  else
    echo $(( interval % 30 + 5 ))  # 5 a 30 seconds
  fi
}

function send_request {
  curl -s -k -o /dev/null -w "%{http_code}" \
    -X GET "$HOST$URI" -H "Content-Type: application/json" \
    --cacert $CACERT --cert $CERT --key $KEY
}

while true; do
  RESPONSE_CODE=$(send_request)

  if (( RANDOM % 5 == 0 )); then  # 25%
    echo "Duplicated request sent"
    RESPONSE_CODE=$(send_request)
  fi

  if (( RANDOM % 5 == 0 )); then  # 25%
    echo "Duplicated request sent"
    RESPONSE_CODE=$(send_request)
  fi

  echo "Request sent by Anomalous bot. Got response: $RESPONSE_CODE"
  INTERVAL=$(get_anomalous_interval)
  sleep $INTERVAL
done

