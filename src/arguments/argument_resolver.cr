# Responsible for resolving the arguments that will be passed to a controller action.
module Athena::Routing::Arguments::ArgumentResolverInterface
  # Returns an array of arguments resolved from the provided *request* for the given *route*.
  abstract def get_arguments(request : HTTP::Request, route : ART::Action) : Array
end

@[ADI::Register("!athena.argument_value_resolver")]
# The default implementation of `ART::Arguments::ArgumentResolverInterface`.
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
        raise ART::Exceptions::BadRequest.new "Missing required parameter '#{param.name}'"
      end
    end
  end
end