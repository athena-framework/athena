A set of abstractions extracted out of the Athena components.
Can be used to build on semantics that the Athena components proved useful.

## Design Principles

This component is a bit special in that it includes two different "kinds" of types,
which have different semantics.

### Contracts

The types defined within the `Athena::Contracts` namespace includes the types and interfaces to achieve loose coupling and interoperability.
These types have backwards compatibility guarantees tied to the version of the `contracts` shard itself.

The intended use case is that other components, or third party libraries, can depend upon the `contracts` component and use its interfaces.
Then, the code could be usable with any implementation that is also based on them.
It could be an Athena component, or another one provided by the greater Crystal community.

### Common

The types not under the `Contracts` namespace are considered just "common" code shared between components.
The backwards compatibility of these types are tied to the component the types related to, _NOT_ the `contracts` shard itself.
