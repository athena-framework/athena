# Responsible for resolving the arguments that will be passed to a controller action.
module Athena::Routing::Arguments::ArgumentResolverInterface
  # Returns an array of arguments resolved from the provided *request* for the given *route*.
  abstract def get_arguments(request : HTTP::Request, route : ART::Action) : Array
end

# :nodoc:
#
# TODO: Revert back to `#map` once [this issue](https://github.com/crystal-lang/crystal/issues/8812) is resolved.
class Array
  def map_first_type
    ary = [] of typeof((yield first))
    each do |e|
      ary << yield e
    end
    ary
  end
end

@[ADI::Register(_resolvers: "!athena.argument_value_resolver")]
# The default implementation of `ART::Arguments::ArgumentResolverInterface`.
struct Athena::Routing::Arguments::ArgumentResolver
  include Athena::Routing::Arguments::ArgumentResolverInterface

  def initialize(@resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface)); end

  # :inherit:
  def get_arguments(request : HTTP::Request, route : ART::Action) : Array
    route.arguments.map_first_type do |param|
      if resolver = @resolvers.find &.supports? request, param
        resolver.resolve request, param
      else
        raise ART::Exceptions::BadRequest.new "Missing required parameter '#{param.name}'"
      end
    end
  end
end
