#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <remote_user> <remote_host>"
    exit 1
fi

set -x

REMOTE_USER=$1
REMOTE_HOST=$2
SERVICE_NAME="envoy"
SERVICE_FILE="$SERVICE_NAME.service"
SCRIPT_NAME="setup.sh"
TMP_DIR="/tmp/envoy-setup"
VM_PASSWORD="AbCd"

LOCAL_API_PATH="../api"
REMOTE_API_PATH="$TMP_DIR/api"

sshpass -p $VM_PASSWORD ssh $REMOTE_USER@$REMOTE_HOST << EOF
  set -x

  mkdir -p $TMP_DIR
EOF

sshpass -p $VM_PASSWORD scp -r $LOCAL_API_PATH $REMOTE_USER@$REMOTE_HOST:$REMOTE_API_PATH

sshpass -p $VM_PASSWORD ssh $REMOTE_USER@$REMOTE_HOST << EOF
  set -x

  sudo su

  apt update
  apt-get -y install golang-go sqlite3

  cd $REMOTE_API_PATH
  go build -o /usr/local/bin/api

  chmod +x $REMOTE_SCRIPT_PATH
  $REMOTE_SCRIPT_PATH $NUM_ITEMS

  mv $REMOTE_SERVICE_PATH /etc/systemd/system/$SERVICE_FILE
  systemctl enable $SERVICE_NAME
  systemctl start $SERVICE_NAME
  systemctl status $SERVICE_NAME

  rm -rf $TMP_DIR
EOF
