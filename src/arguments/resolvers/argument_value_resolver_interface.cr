module Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  # The priority of `self`.  The higher the value the sooner the resolver gets executed.
  def self.priority : Int32
    0
  end

  # Returns `true` if `self` is able to resolve a value from the provided *request* and *argument*.
  abstract def supports?(request : HTTP::Request, argument : Athena::Routing::Arguments::ArgumentMetadata) : Bool

  # Returns a value resolved from the provided *request* and *argument*.
  abstract def resolve(request : HTTP::Request, argument : Athena::Routing::Arguments::ArgumentMetadata)
end
