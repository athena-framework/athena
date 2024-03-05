require "./annotations"
require "./event_dispatcher"
require "./generic_event"

# Convenience alias to make referencing `Athena::EventDispatcher` types easier.
alias AED = Athena::EventDispatcher

# Convenience alias to make referencing `AED::Annotations` types easier.
alias AEDA = AED::Annotations

module Athena::EventDispatcher
  VERSION = "0.2.3"

  # Contains all the `Athena::EventDispatcher` based annotations.
  module Annotations; end
end
