It's usually considered a best practice to run an application behind a reverse proxy or load balancer.
For the most part, this doesn't cause any problems with Athena.
But, when a request passes through a proxy, certain request information is sent using either the standard `forwarded` header or `x-forwarded-*` headers.
For example, instead of reading the request's [`#remote_address`](https://crystal-lang.org/api/HTTP/Request.html#remote_address%3ASocket%3A%3AAddress%7CNil-instance-method) (which will now be the IP address of your reverse proxy), the scheme of the original request will be stored in a standard `Forwarded: proto="..."` header or a `x-forwarded-proto` header.

If you don't configure Athena to look for these headers, you'll get incorrect information about the request, such as if the client is connecting via HTTPS, the client's port and the hostname being requested.

## Trusted Proxies

To solve this problem, you need to tell Athena which IP addresses belong to proxies you trust, and which headers the proxy uses to send information.
This can be accomplished via the [`framework.trusted_proxies`](/Framework/Bundle/Schema/#Athena::Framework::Bundle::Schema#trusted_proxies) and [`framework.trusted_headers`](http://localhost:8000/Framework/Bundle/Schema/#Athena::Framework::Bundle::Schema#trusted_headers) configuration properties respectively.

```crystal
ATH.configure({
  framework: {
    # The IP address (or range) of your proxy.
    trusted_proxies: ["192.0.0.1", "10.0.0.0/8"],

    # Trust only `x-forwarded-port` and `x-forwarded-proto` headers.
    trusted_headers: ATH::Request::ProxyHeader[:forwarded_port, :forwarded_proto]
  },
})
```

DANGER: Enabling the [ATH::Request::ProxyHeader::FORWARDED_HOST](/Framework/Request/ProxyHeader/#Athena::Framework::Request::ProxyHeader::FORWARDED_HOST) option exposes the application to [HTTP Host header attacks](https://www.skeletonscribe.net/2013/05/practical-http-host-header-attacks.html).
Make sure the proxy really sends an `x-forwarded-host` header to avoid client supplied ones being passed through.

WARNING: The "trusted proxies" feature does not work as expected when using the [nginx realip module](https://nginx.org/en/docs/http/ngx_http_realip_module.html).
Disable that module when serving Athena applications.

## Dynamic IPs

Some proxies do not have static IP addresses or even a range that you can target with CIDR notation.
In this case, you need to - _very carefully_ - trust _all_ proxies.

1. Ensure your web server(s) do _NOT_ respond to traffic from _ANY_ clients other than your load balancer.
1. Once you're guaranteed that traffic will only come from your trusted proxies, configure Athena to _always_ trust incoming request:

```crystal
ATH.configure({
  framework: {
    # The `"REMOTE_ADDRESS"` string will be replaced by the IP address from the request's `#remote_address`.
    trusted_proxies: ["127.0.0.1", "REMOTE_ADDRESS"],
  },
})
```

That's it! It's critical that you prevent traffic from all non-trusted sources. If you allow outside traffic, they could "spoof" their true IP address and other information.

<!-- ## Reverse Proxy in a Subpath -->

## Custom Headers

Some reverse proxies do not use the common `x-forwarded-*` header names and may force you to use a custom header.
In such cases you can use the [`framework.trusted_header_overrides`](/Framework/Bundle/Schema/#Athena::Framework::Bundle::Schema#trusted_header_overrides) configuration property to handle this:

```crystal
ATH.configure({
  framework: {
    # Tell Athena to look for `cloudfront-forwarded-proto` instead of the default `x-forwarded-proto`.
    trusted_header_overrides: {
      :forwarded_proto => "cloudfront-forwarded-proto",
    },
  },
})
```
