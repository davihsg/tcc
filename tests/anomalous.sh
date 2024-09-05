#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
USER="2"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$CERTS_FOLDERS/bundle.$USER.pem"
CERT="$CERTS_FOLDERS/svid.$USER.pem"
KEY="$CERTS_FOLDERS/svid.$USER.key"
INTERVAL=1
RATE=0
WORKERS=100
DURATION="15m" # 15 minutes

attack() {
  echo "GET $HOST$URI" | vegeta attack \
    -cert $CERT \
    -key $KEY \
    -root-certs $CACERT \
    -insecure \
    -rate=$RATE \
    -max-workers=$WORKERS \
    -duration=$DURATION | vegeta report -type=json
}

stop() {
  echo "[anomalous] stopping attack..."
  pkill -P $$
  exit 0
}

trap "stop" SIGINT
trap "stop" SIGTERM

echo "[anomalous] starting DDoS attack with $REQUESTS requests"

attack

echo "[anomalous] DDoS attack finished (for now)"

