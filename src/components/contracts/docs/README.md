A set of abstractions extracted out of the Athena components.
Can be used to build on semantics that the Athena components proved useful.

## Usage

The [Athena::Contracts][] component provides types and interfaces to achieve loose coupling and interoperability.
The intended use case is that other components, or third party libraries, can depend upon the `contracts` component and use its interfaces.
Then, the code could be usable with any implementation that is also based on them.
It could be an Athena component, or another one provided by the greater Crystal community.
