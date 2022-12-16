require "./argument_resolvers/interface"
require "./argument_resolver_interface"

ADI.bind argument_resolvers : Array(Athena::Framework::Controller::ArgumentResolvers::Interface), "!athena.argument_value_resolver"

@[ADI::Register]
# The default implementation of `ATH::Controller::ArgumentResolverInterface`.
struct Athena::Framework::Controller::ArgumentResolver
  include Athena::Framework::Controller::ArgumentResolverInterface

  def initialize(@argument_resolvers : Array(ATHR::Interface)); end

  # :inherit:
  def get_arguments(request : ATH::Request, route : ATH::ActionBase) : Array
    route.resolve_arguments @argument_resolvers, request
  end
end
