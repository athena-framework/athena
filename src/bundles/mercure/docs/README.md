TODO: Write me

## Installation

First, install the bundle by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-BUNDLE_NAME_bundle:
    github: athena-framework/BUNDLE_NAME-bundle
    version: ~> 0.1.0
```

Then, register it:
```crystal
ADI.register_bundle Athena::NAMESPACE_NAME
```

Finally, optionally configure it:
```crystal
ADI.configure({
  BUNDLE_NAME: {
    foo: bar
  },
})
````

## Usage

TODO: Write me
