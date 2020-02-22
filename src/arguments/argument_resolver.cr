# :nodoc:
module Athena::Routing::Arguments::ArgumentResolverInterface
  # Returns an array of arguments resolved from the provided *request* for the given *route*.
  abstract def get_arguments(request : HTTP::Request, route : ART::Action) : Array
end

@[ADI::Register("!athena.argument_value_resolver")]
# :nodoc:
#
# A service that encapsulates the logic for resolving action arguments from a request.
struct Athena::Routing::Arguments::ArgumentResolver
  include Athena::Routing::Arguments::ArgumentResolverInterface
  include ADI::Service

  @resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface)

  def initialize(resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface))
    @resolvers = resolvers.sort_by!(&.class.priority).reverse!
  end

  # :inherit:
  def get_arguments(request : HTTP::Request, route : ART::Action) : Array
    route.arguments.map do |param|
      if resolver = @resolvers.find &.supports? request, param
        next resolver.resolve request, param
      else
        raise "Controller action #{route.controller}##{route.action_name} requires a value for the '#{param.name}' argument."
      end
    end
  end
end
