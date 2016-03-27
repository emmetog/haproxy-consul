FROM haproxy:1.6.4-alpine

MAINTAINER Emmet O'Grady <emmet789@gmail.com>

ENV CONSUL_TEMPLATE_VERSION 0.7.0

ADD haproxy.conf /etc/haproxy/haproxy.conf

ADD start.sh /start.sh
RUN chmod u+x /start.sh
ADD reload_haproxy.sh /reload_haproxy.sh
RUN chmod u+x /reload_haproxy.sh

RUN apk update \
    && apk add curl \
    && curl -L -o /tmp/consul-template.tar.gz https://github.com/hashicorp/consul-template/releases/download/v0.7.0/consul-template_0.7.0_linux_amd64.tar.gz \
    && cd /tmp \
    && tar -xzf consul-template.tar.gz \
    && cp consul-template_0.7.0_linux_amd64/consul-template /usr/local/bin/consul-template \
    && rm -rf /tmp/consul* \
    && chmod a+x /usr/local/bin/consul-template \
    && apk del curl