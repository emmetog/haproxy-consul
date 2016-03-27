#!/bin/sh
echo "DEBUG: restarting haproxy"
haproxy -f /etc/haproxy/haproxy.conf -p /var/run/haproxy.pid -D -st $(cat /var/run/haproxy.pid)
