@[ADI::Register(tags: ["athena.argument_value_resolver"])]
struct Athena::Routing::Arguments::Resolvers::DefaultValue
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  include ADI::Service

  # :inherit:
  def self.priority : Int32
    -100
  end

  # :inherit:
  def supports?(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument) : Bool
    argument.has_default? || (argument.type == Nil && argument.nillable?)
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : Athena::Routing::Arguments::Argument)
    argument.has_default? ? argument.default : nil
  end
end
