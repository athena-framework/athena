require "./resolvers/argument_value_resolver_interface"
require "./argument_resolver_interface"

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

ADI.bind argument_resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface), "!athena.argument_value_resolver"

@[ADI::Register]
# The default implementation of `ART::Arguments::ArgumentResolverInterface`.
struct Athena::Routing::Arguments::ArgumentResolver
  include Athena::Routing::Arguments::ArgumentResolverInterface

  def initialize(@argument_resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface)); end

  # :inherit:
  def get_arguments(request : HTTP::Request, route : ART::ActionBase) : Array
    route.arguments.map_first_type do |param|
      if resolver = @argument_resolvers.find &.supports? request, param
        resolver.resolve request, param
      else
        raise RuntimeError.new "Could not resolve required argument '#{param.name}' for '#{route.controller}##{route.name}'."
      end
    end
  end
end
