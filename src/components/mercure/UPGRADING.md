# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### The `jwt` shard is an optional dependency

The component no longer depends on the [jwt](https://github.com/crystal-community/jwt) shard.
It is only needed to generate the JWTs used to authorize with a hub, such as via `AMC::TokenFactory::JWT`, or a hub configured with a `secret` in the [bundle](https://athenaframework.org/Mercure/Bundle/).
Applications that do so need to add it to their `shard.yml` and require it:

```yaml
dependencies:
  jwt:
    github: crystal-community/jwt
    version: ~> 1.7
```

```crystal
require "jwt"
```

Applications that only use static tokens, such as hubs configured with `jwt.value`, do not need it.

### The bundle's `jwt.algorithm` only accepts a symbol

The `jwt.algorithm` configuration of a hub only accepts the name of the algorithm as a symbol, as it can no longer be typed as a `JWT::Algorithm`.

Before:

```crystal
jwt: {
  secret:    ENV["MERCURE_JWT_SECRET"],
  algorithm: JWT::Algorithm::HS384,
},
```

After:

```crystal
jwt: {
  secret:    ENV["MERCURE_JWT_SECRET"],
  algorithm: :hs384,
},
```

### The Mercure protocol 1.0 is the default

`AMC::Hub`, `AMC::Spec::MockHub`, `AMC::TokenFactory::JWT`, and the hubs of the bundle speak the [Mercure protocol 1.0](https://mercure.rocks/spec) by default, as implemented by Mercure hubs 1.0 and newer.
Its JWTs are [RFC 9068](https://datatracker.ietf.org/doc/html/rfc9068) access tokens: `AMC::TokenFactory::JWT` encodes the grants as an `authorization_details` claim instead of a `mercure` claim, and requires the `iss`, `aud`, `sub`, and `client_id` claims.
The default name of the authorization cookie is `__Secure-mercure_access_token` instead of `mercureAuthorization`, and it is only marked secure if the hub's public URL is served over HTTPS.

To keep using a hub older than 1.0, opt into the 0.x protocol.

Before:

```crystal
token_factory = AMC::TokenFactory::JWT.new ENV["MERCURE_JWT_SECRET"]
hub = AMC::Hub.new ENV["MERCURE_URL"], token_provider, token_factory
```

After:

```crystal
token_factory = AMC::TokenFactory::JWT.new ENV["MERCURE_JWT_SECRET"], protocol_version: :legacy
hub = AMC::Hub.new ENV["MERCURE_URL"], token_provider, token_factory, protocol_version: :legacy
```

Or within the bundle:

```crystal
hubs: {
  default: {
    url:              ENV["MERCURE_URL"],
    protocol_version: "0.x",
    jwt:              {
      secret: ENV["MERCURE_JWT_SECRET"],
    },
  },
},
```

Otherwise, hubs of the bundle configured with a `secret` must define the `iss`, `sub`, and `client_id` claims, while `aud` defaults to the hub's URL:

```crystal
jwt: {
  secret: ENV["MERCURE_JWT_SECRET"],
  claims: {
    "iss"       => "https://example.com",
    "sub"       => "urn:example:app",
    "client_id" => "https://example.com",
  },
},
```

Similarly, wrap an `AMC::TokenFactory::JWT` used without the bundle in an `AMC::TokenFactory::DefaultClaims` to add the claims to every token it creates.

### Tokens are created from grants

`AMC::TokenFactory::Interface#create` accepts a list of `AMC::Grant` instead of the topics to subscribe and publish to, as does `AMC::TokenProvider::Factory`.
`AMC::TokenProvider::Factory` also accepts *additional_claims* to add to the token.

Before:

```crystal
token_factory.create ["https://example.com/books/1"], ["*"]
AMC::TokenProvider::Factory.new token_factory, publish: ["*"]
```

After:

```crystal
token_factory.create [AMC::Grant.new(:subscribe, ["https://example.com/books/1"]), AMC::Grant.new(:publish, ["*"])]
AMC::TokenProvider::Factory.new token_factory, [AMC::Grant.new(:publish, ["*"])]
```

Custom `AMC::TokenFactory::Interface` implementations must implement the new signature, and `AMC::Hub::Interface` implementations the new `#protocol_version` and `#cookie_name` methods.
`AMC::Spec::AssertingTokenFactory` asserts the grants instead of the topics.

### Authorization cookies are created from grants

`AMC::Authorization#set_cookie` and `#create_cookie`, and their `AMC::Bundle::Authorization` counterparts, accept the grants of the token instead of the topics to subscribe and publish to.
The grants may also be a topic, a list of topics, or a hash of topic matchers to subscribe to.

Before:

```crystal
authorization.set_cookie request, response, ["https://example.com/books/1"], ["https://example.com/books/1/comments"]
```

After:

```crystal
authorization.set_cookie request, response, [
  AMC::Grant.new(:subscribe, ["https://example.com/books/1"]),
  AMC::Grant.new(:publish, ["https://example.com/books/1/comments"]),
]
```

Calls that only pass the topics to subscribe to as a positional argument continue to work as is.
