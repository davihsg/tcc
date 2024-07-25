#!/bin/bash

WORK_DIR="/home/spire"
VERSION="1.10.0"
SPIRE_DIR="$WORK_DIR/spire-$VERSION"

cd $WORK_DIR

if [ ! -d "$SPIRE_DIR"]; then
  curl -s -N -L "https://github.com/spiffe/spire/releases/download/v$VERSION/spire-$VERSION-linux-amd64-musl.tar.gz | tar xz
fi

cd $SPIRE_DIR

bin/spire-server run -config conf/server/server.conf &

bin/spire-server healthcheck
