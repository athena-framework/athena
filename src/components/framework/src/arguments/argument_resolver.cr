require "./resolvers/interface"
require "./argument_resolver_interface"

ADI.bind argument_resolvers : Array(Athena::Framework::Arguments::Resolvers::Interface), "!athena.argument_value_resolver"

@[ADI::Register]
# The default implementation of `ATH::Arguments::ArgumentResolverInterface`.
struct Athena::Framework::Arguments::ArgumentResolver
  include Athena::Framework::Arguments::ArgumentResolverInterface

  def initialize(@argument_resolvers : Array(Athena::Framework::Arguments::Resolvers::Interface)); end

  # :inherit:
  def get_arguments(request : ATH::Request, route : ATH::ActionBase) : Array
    route.resolve_arguments @argument_resolvers, request
  end
end
