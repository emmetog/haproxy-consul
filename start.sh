#!/bin/sh

HAPROXY_ROOT=/etc/haproxy
CONFIG_FILE=${HAPROXY_ROOT}/haproxy.cfg
TEMPLATE=${HAPROXY_ROOT}/haproxy.template

CONSUL_SERVER=${CONSUL_SERVER:-consul}
CONSUL_PORT=${CONSUL_PORT:-8500}

cd "$HAPROXY_ROOT"

service restart haproxy

/usr/local/bin/consul-template -consul $CONSUL_SERVER:$CONSUL_PORT \
    -template "$TEMPLATE:$CONFIG_FILE:/reload_haproxy.sh" \
    -log-level debug