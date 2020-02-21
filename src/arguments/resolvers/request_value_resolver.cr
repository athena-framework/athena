@[ADI::Register(tags: ["athena.argument_value_resolver"])]
struct Athena::Routing::Arguments::Resolvers::Request
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  include ADI::Service

  # :inherit:
  def supports?(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument) : Bool
    HTTP::Request >= argument.type
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument)
    request
  end
end
