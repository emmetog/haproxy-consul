# HAProxy with Consul Template

[![](https://badge.imagelayers.io/emmetog/haproxy-consul:latest.svg)](https://imagelayers.io/?images=emmetog/haproxy-consul:latest 'Image size')

This image contains a haproxy server whose configuration is generated from
the services registered in consul.

There are two things running in this container: haproxy and consul-template.
Consul-template watches the consul server and regenerates the haproxy
configuration file when anything changes in consul. After regenerating
the configuration file consul-template restarts haproxy so that the
new configuration is used.

## Usage

Run this container like this:
```
$ docker run -d \
    -p 80:80 \
    -p 443:443 \
    -v /path/to/haproxy/template:/etc/haproxy/haproxy.template:ro \
    --link consul:consul \
    emmetog/haproxy-consul
```

***Note***: there is no haproxy config template file in this container, you **must** map your own
template into `/etc/haproxy/haproxy.template`.

You can either create your own new docker image which is based on this one and hardcode
your template inside, or you can run this container directly and map your template into
the container as a volume, as in the example above.

## Consul server

By default the container assumes that the consul server is reachable through the hostname
"consul". This makes it easy to get started, all you need to do is link this container
to the consul container using the alias "consul". However if you
want to change the hostname that consul-template uses to connect to the consul server, set
the `CONSUL_SERVER` environmental variable. Similarly, you can change the port using the
`CONSUL_PORT` environmental variable (default is 8500). If you do specify the `CONSUL_SERVER`
then you don't need to link to the consul container.

In the following example we are using the internal DNS of docker to resolve the hostname
"consul.service.consul" but you could also specify an IP.

```
$ docker run -d \
    -p 80:80 \
    -p 443:443 \
    -v /path/to/haproxy/template:/etc/haproxy/haproxy.template:ro \
    -e CONSUL_SERVER consul.service.consul \
    -e CONSUL_PORT 8500 \
    emmetog/haproxy-consul
```

## Template examples

Here are a few example HAProxy templates to get you started.

### Example template with multiple HTTPS domains

This template uses SNI to allow this load balancer to terminate multiple SSL
domains. This is very useful when you have multiple domains all pointing to the
same IP and you want your load balancer to send the traffic for each domain
to separate services. In this template there an example of a normal HTTP
endpoint which doesn't use SSL (site3). For this template to work you will
have to add the tags "site1", "site2" and "site3" to the corresponding services
when registering the services in consul. You will also need to add the certs
into `/etc/haproxy/certs`.

Normally [registrator](https://github.com/gliderlabs/registrator) is used to
automatically register the services in consul.

```
global
    tune.ssl.default-dh-param 2048

frontend www-in
    bind *:80
    bind *:443 ssl crt /etc/haproxy/certs/

    # Site1 (uses SSL only, non-HTTPS is redirected to HTTPS)
    acl is_site1 req_ssl_sni -i site1.com
    redirect scheme https code 301 if is_site1 !{ ssl_fc }
    use_backend site1_cluster if is_site1

    # Site2 (uses SSL only, non-HTTPS is redirected to HTTPS)
    acl is_site2 req_ssl_sni -i site2.com
    redirect scheme https code 301 if is_site2 !{ ssl_fc }
    use_backend site2_cluster if is_site2

    # Site3 (No SSL, only available through HTTP)
    acl is_site3 hdr(host) -i site3.com
    use_backend site3_cluster if is_site3

backend site1_cluster
    {{range services}}{{$service:=.Name}}{{range .Tags}}{{if eq . "site1" }}{{range service $service "passing" }}
    {{range service .Name}}server {{.Node}} {{.Address}}:{{.Port}} check{{end}}
    {{end}}{{end}}{{end}}{{end}}

backend site2_cluster
    {{range services}}{{$service:=.Name}}{{range .Tags}}{{if eq . "site2" }}{{range service $service "passing" }}
    {{range service .Name}}server {{.Node}} {{.Address}}:{{.Port}} check{{end}}
    {{end}}{{end}}{{end}}{{end}}

backend site3_cluster
    {{range services}}{{$service:=.Name}}{{range .Tags}}{{if eq . "site3" }}{{range service $service "passing" }}
    {{range service .Name}}server {{.Node}} {{.Address}}:{{.Port}} check{{end}}
    {{end}}{{end}}{{end}}{{end}}
```

### Example template

This template will (todo: explain this)
```
global
  log 127.0.0.1 local0
  log 127.0.0.1 local1 notice
  user haproxy
  group haproxy

defaults
  log global
  mode http
  option httplog
  option dontlognull

frontend web-app
  bind *:80
  default_backend default

backend default
  balance roundrobin
{{range $tag, $services := service "webapp" | byTag}}
 {{with $d := key "backend/current"}}
  {{if $d}}
   {{if eq $tag $d}}
    {{range $services}} server {{.ID}} {{.Address}}:{{.Port}}
   {{end}}
  {{end}}
 {{end}}
{{end}}{{end}}
```

## Contributions

Contributions are more than welcome, just fork this project and create a pull request.