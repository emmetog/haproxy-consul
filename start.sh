#!/bin/sh

set -e

HAPROXY_ROOT=/etc/haproxy
CONFIG_FILE=${HAPROXY_ROOT}/haproxy.cfg
TEMPLATE=${HAPROXY_ROOT}/haproxy.template

CONSUL_SERVER=${CONSUL_SERVER:-consul}
CONSUL_PORT=${CONSUL_PORT:-8500}
LOG_LEVEL=${LOG_LEVEL:-warn}

cd "$HAPROXY_ROOT"

service haproxy start

/usr/local/bin/consul-template -consul $CONSUL_SERVER:$CONSUL_PORT \
    -template "$TEMPLATE:$CONFIG_FILE:/reload_haproxy.sh" \
    -log-level "$LOG_LEVEL"
