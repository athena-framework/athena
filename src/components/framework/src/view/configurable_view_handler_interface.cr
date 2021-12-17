# These live here so `Athena::Framework::View` is correctly created as a class versus a module.

# Parent type of a view just used for typing.
#
# See `ATH::View`.
module Athena::Framework::ViewBase; end

class Athena::Framework::View(T)
  include Athena::Framework::ViewBase
end

require "./view_handler_interface"

# Specialized `ATH::View::ViewHandlerInterface` that allows controlling various serialization `ATH::View::Context` aspects dynamically.
module Athena::Framework::View::ConfigurableViewHandlerInterface
  include Athena::Framework::View::ViewHandlerInterface

  # Sets the *groups* that should be used as part of `ASR::ExclusionStrategies::Groups`.
  abstract def serialization_groups=(groups : Enumerable(String)) : Nil

  # Sets the *version* that should be used as part of `ASR::ExclusionStrategies::Version`.
  abstract def serialization_version=(version : SemanticVersion) : Nil

  # Determines if properties with `nil` values should be emitted.
  abstract def emit_nil=(emit_nil : Bool) : Nil
end
