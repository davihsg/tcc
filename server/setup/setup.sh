#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <remote_user> <remote_host> <num_items>"
    exit 1
fi

set -x

REMOTE_USER=$1
REMOTE_HOST=$2
NUM_ITEMS=$3
SERVICE_NAME="api"
SERVICE_FILE="$SERVICE_NAME.service"
SCRIPT_NAME="setup_db.sh"
TMP_DIR="/tmp/api-setup"
VM_PASSWORD="AbCd"

LOCAL_SCRIPT_PATH="./$SCRIPT_NAME"
REMOTE_SCRIPT_PATH="$TMP_DIR/$SCRIPT_NAME"
LOCAL_SERVICE_PATH="./$SERVICE_FILE"
REMOTE_SERVICE_PATH="$TMP_DIR/$SERVICE_FILE"
LOCAL_API_PATH="../api"
REMOTE_API_PATH="$TMP_DIR/api"

sshpass -p $VM_PASSWORD ssh $REMOTE_USER@$REMOTE_HOST << EOF
  set -x

  mkdir -p $TMP_DIR
EOF

sshpass -p $VM_PASSWORD scp $LOCAL_SCRIPT_PATH $REMOTE_USER@$REMOTE_HOST:$REMOTE_SCRIPT_PATH
sshpass -p $VM_PASSWORD scp $LOCAL_SERVICE_PATH $REMOTE_USER@$REMOTE_HOST:$REMOTE_SERVICE_PATH
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
