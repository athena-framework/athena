module Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  abstract def supports?(request : HTTP::Request, argument : Athena::Routing::Arguments::ArgumentMetadata) : Bool
  abstract def resolve(request : HTTP::Request, argument : Athena::Routing::Arguments::ArgumentMetadata)
end
