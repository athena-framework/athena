require "./value_resolvers/interface"
require "./argument_resolver_interface"

ADI.bind value_resolvers : Array(Athena::Framework::Controller::ValueResolvers::Interface), "!athena.controller.value_resolver"

@[ADI::Register]
@[ADI::AsAlias]
# The default implementation of `ATH::Controller::ArgumentResolverInterface`.
struct Athena::Framework::Controller::ArgumentResolver
  include Athena::Framework::Controller::ArgumentResolverInterface

  def initialize(@value_resolvers : Array(Athena::Framework::Controller::ValueResolvers::Interface)); end

  # :inherit:
  def get_arguments(request : ATH::Request, route : ATH::ActionBase) : Array
    route.resolve_arguments @value_resolvers, request
  end
end
