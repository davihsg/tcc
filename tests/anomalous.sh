#!/bin/bash

HOST="https://localhost:10000"
URI="/items"
USER="0"
CERTS_FOLDERS="$HOME/tcc/users"
CACERT="$CERTS_FOLDERS/bundle.$USER.pem"
CERT="$CERTS_FOLDERS/svid.$USER.pem"
KEY="$CERTS_FOLDERS/svid.$USER.key"
TARGETS_FILE="anomalous_targets.txt"
REPORT_FILE="anomalous_$(date +%s).report"
INTERVAL=1
RATE=500
WORKERS=100
DURATION="50s"

attack() {
  vegeta attack \
    -cert=$CERT \
    -key=$KEY \
    -targets=$TARGETS_FILE \
    -root-certs=$CACERT \
    -max-body=0 \
    -insecure \
    -rate=$RATE \
    -workers=100 \
    -duration=$DURATION | vegeta report >> $REPORT_FILE
}

stop() {
  echo "[anomalous] stopping attack..."
  pkill -P $$
  exit 0
}

echo "[anomalous] creating targets file"

if [ ! -f "$TARGETS_FILE" ]; then
  echo "GET $HOST$URI" > $TARGETS_FILE
  echo "[anomalous] targets created with default route"
else
  echo "[anomalous] targets already exists, skipping..."
fi

trap "stop" SIGINT
trap "stop" SIGTERM

echo "[anomalous] starting DDoS attack for $DURATION"

attack

echo "[anomalous] DDoS attack finished (for now)"

