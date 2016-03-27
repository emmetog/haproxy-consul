# HAProxy with Consul Template

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
$ docker run -d -v /path/to/haproxy/template:/etc/haproxy/haproxy.template:ro emmetog/haproxy-consul
```

Note: there is no haproxy config template file in this container, you *must* map your own
template into `/etc/haproxy/haproxy.template`.

You can either create your own new docker image which is based on this one and hardcode
your template inside, or you can run this container directly and map your template into
the container as a volume.

## Template examples

Here are a few example HAProxy templates to get you started.

### Example template with multiple HTTPS domains

This template uses SNI to allow this load balancer to terminate multiple SSL
domains. This is very useful when you have multiple domains all pointing to the
same IP and you want your load balancer to send the traffic for each domain
to separate services. In this template there an example of a normal HTTP
endpoint which doesn't use SSL (site3). For this template to work you will
have to add the tags "site1", "site2" and "site3" to the corresponding services
when registering the services in consul.

Normally [registrator](https://github.com/gliderlabs/registrator) is used to
automatically register the services in consul.

```
global
    tune.ssl.default-dh-param 2048

frontend www-in
    bind *:443 ssl crt /etc/proxy/certs/

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