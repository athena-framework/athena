# These live here so `Athena::Routing::View` is correctly created as a class versus a module.

# Parent type of a view just used for typing.
#
# See `ART::View`.
abstract class Athena::Routing::ViewBase; end

class Athena::Routing::View(T) < Athena::Routing::ViewBase; end

require "./view_handler_interface"

# Specialized `ART::View::ViewHandlerInterface` that allows controlling various serialization `ART::View::Context` aspects dynamically.
module Athena::Routing::View::ConfigurableViewHandlerInterface
  include Athena::Routing::View::ViewHandlerInterface

  # Sets the *groups* that should be used as part of `ASR::ExclusionStrategies::Groups`.
  abstract def serialization_groups=(groups : Enumerable(String)) : Nil

  # Sets the *version* that should be used as part of `ASR::ExclusionStrategies::Version`.
  abstract def serialization_version=(version : SemanticVersion) : Nil

  # Determines if properties with `nil` values should be emitted.
  abstract def emit_nil=(emit_nil : Bool) : Nil
end
