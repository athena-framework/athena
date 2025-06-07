# Main entrypoint that requires _all_ contracts.
# Does _not_ include common code as those are required by the underlying component,
# for docs, tests, etc.

require "./event_dispatcher"
require "./alias"

# A set of robust/battle-tested types and interfaces to achieve loose coupling and interoperability.
module Athena::Contracts
  # Contracts that relate to the [Athena::EventDispatcher](/EventDispatcher/) component.
  module EventDispatcher; end
end
