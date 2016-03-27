#!/bin/bash

HAPROXY_ROOT=/etc/haproxy
PIDFILE=/var/run/haproxy.pid
CONFIG_FILE=${HAPROXY_ROOT}/haproxy.conf
TEMPLATE=${HAPROXY_ROOT}/haproxy.template

CONSUL_SERVER=${CONSUL_SERVER:-consul}
CONSUL_PORT=${CONSUL_PORT:-8500}

cd "$HAPROXY_ROOT"

haproxy -f "$CONFIG_FILE" -p "$PIDFILE" -D -st $(cat $PIDFILE)

/usr/local/bin/consul-template -consul $CONSUL_SERVER:$CONSUL_PORT \
    -template "$TEMPLATE:$CONFIG_FILE:/reload_haproxy.sh" \
    -log-level debug