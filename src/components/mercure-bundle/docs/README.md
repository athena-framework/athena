## Installation

First, install the bundle by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-mercure_bundle:
    github: athena-framework/mercure-bundle
    version: ~> 0.1.0
```

Then, register it:
```crystal
ADI.register_bundle Athena::MercureBundle
```

Finally, optionally configure it:
```crystal
ADI.configure({
  mercure: {
    foo: bar
  },
})
```

## Usage

TODO: Write me
