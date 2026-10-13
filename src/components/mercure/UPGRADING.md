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
