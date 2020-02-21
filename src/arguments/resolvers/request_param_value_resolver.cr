@[ADI::Register(tags: ["athena.argument_value_resolver"])]
struct Athena::Routing::Arguments::Resolvers::Parameter
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  include ADI::Service

  # :inherit:
  def supports?(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument) : Bool
    request.params.has? argument.name
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument)
    value = request.params.get argument.name

    argument.type.from_parameter value
  rescue ex : ArgumentError
    # Catch type cast errors and bubble it up as an UnprocessableEntity
    raise ART::Exceptions::UnprocessableEntity.new "Required parameter '#{argument.name}' with value '#{value}' could not be converted into a valid '#{argument.type}'", cause: ex
  end
end
