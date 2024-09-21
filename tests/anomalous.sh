#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
USER="2"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$CERTS_FOLDERS/bundle.$USER.pem"
CERT="$CERTS_FOLDERS/svid.$USER.pem"
KEY="$CERTS_FOLDERS/svid.$USER.key"
TARGETS_FILE="targets.txt"
INTERVAL=1
RATE=0
WORKERS=100
DURATION="50s"

attack() {
  vegeta attack \
    -cert $CERT \
    -key $KEY \
    -targets=targets.txt \
    -root-certs $CACERT \
    -insecure \
    -rate=$RATE \
    -max-workers=$WORKERS \
    -duration=$DURATION | vegeta report >> anomalous.report
}

stop() {
  echo "[anomalous] stopping attack..."
  pkill -P $$
  exit 0
}

echo "[anomalous] creating targets file"

if [ ! -f "targets.txt" ]; then
  echo "GET $HOST$URI" > targets.txt
  echo "[anomalous] targets created with default route"
else
  echo "[anomalous] targets already exists, skipping..."
fi

trap "stop" SIGINT
trap "stop" SIGTERM

echo "[anomalous] starting DDoS attack with $REQUESTS requests"

attack

echo "[anomalous] DDoS attack finished (for now)"

