The `Athena::Clock` component allows decoupling an application from the system clock.
This allows for more easily testing time sensitive code.

The component provides a [ACLK::Interface][] with the following implementations for different use cases:

* [ACLK::Native][] - Provides access to the system clock for most usages
* [ACLK::Monotonic][] - Provides access to a high resolution, monotonic clock for when needing to measure time precisely
* [ACLK::Spec::MockClock][] - Provides the ability to freeze and change the current time for use in tests

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-clock:
    github: athena-framework/clock
    version: ~> 0.1.0
```

## Usage

The core `Athena::Clock` type can be used to return the current time via a global clock.

```crystal
# By default, `Athena::Clock` uses the native clock implementation,
# but it can be changed to any other implementation
Athena::Clock.clock = ACLK::Monotonic.new

# Then, obtain a clock instance
clock = ACLK.clock

# Optionally, with in a specific location
berlin_clock = clock.in_location Time::Location.load "Europe/Berlin"

# From here, get the current time as a `Time` instance
now = clock.now # : ::Time

# and sleep for any period of time
clock.sleep 2
```
