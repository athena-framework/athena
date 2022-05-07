require "./resolvers/interface"
require "./argument_resolver_interface"

# :nodoc:
class Array
  # :nodoc:
  #
  # TODO: Revert back to `#map` once [this issue](https://github.com/crystal-lang/crystal/issues/8812) is resolved.
  def map_first_type
    ary = [] of typeof((yield first))
    each do |e|
      ary << yield e
    end
    ary
  end
end

ADI.bind argument_resolvers : Array(Athena::Framework::Arguments::Resolvers::Interface), "!athena.argument_value_resolver"

@[ADI::Register]
# The default implementation of `ATH::Arguments::ArgumentResolverInterface`.
struct Athena::Framework::Arguments::ArgumentResolver
  include Athena::Framework::Arguments::ArgumentResolverInterface

  def initialize(@argument_resolvers : Array(Athena::Framework::Arguments::Resolvers::Interface)); end

  # :inherit:
  def get_arguments(request : ATH::Request, route : ATH::ActionBase) : Array
    route.arguments.map_first_type do |param|
      if resolver = @argument_resolvers.find &.supports? request, param
        resolver.resolve request, param
      else
        raise RuntimeError.new %(Could not resolve required argument '#{param.name}' for '#{request.attributes.get "_route"}'.)
      end
    end
  end
end
