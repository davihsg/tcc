#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <host_address <user_name>"
    exit 1
fi

USER_NAME=$1

adduser $USER_NAME

passwd $USER_NAME

cat << EOF >/etc/sudoers.d/$USER_NAME
$USER_NAME ALL = (root) NOPASSWD:ALL
EOF

chmod 0440 /etc/sudoers.d/$USER_NAME
