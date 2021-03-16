# These live here so `Athena::Routing::View` is correctly created as a class versus a module.

abstract class Athena::Routing::ViewBase; end

class Athena::Routing::View(T) < Athena::Routing::ViewBase; end

require "./view_handler_interface"

module Athena::Routing::View::ConfigurableViewHandlerInterface
  include Athena::Routing::View::ViewHandlerInterface

  abstract def serialization_groups=(groups : Enumerable(String)) : Nil
  abstract def serialization_version=(version : SemanticVersion) : Nil
  abstract def emit_nil=(emit_nil : Bool) : Nil
end
