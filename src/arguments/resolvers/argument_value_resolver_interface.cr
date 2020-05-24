# Argument value resolvers handle resolving the arguments for a controller action from a request, or other source.
#
# Custom resolvers can be defined by creating a service that implements this interface, and is tagged with `ART::Arguments::Resolvers::TAG`,
# optionally with a priority to determine the order in which the resolvers are executed.
#
# ```
# @[ADI::Register(tags: [{name: ART::Arguments::Resolvers::TAG, priority: 10}])]
# struct CustomResolver
#   include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
#
#   # :inherit:
#   def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
#     # Define the logic that determines if `self` is able to resolve a value for the given request/argument.
#     # This resolver would handle resolving a value for action arguments whose type is `MyCustomType`.
#     argument.type == MyCustomType
#   end
#
#   # :inherit:
#   def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata)
#     # Return the resolved value.  It could either come from the request itself, an injected service, or hardcoded.
#     # `#resolve` is only executed if `#supports?` returns `true`.
#     MyCustomType.new "foo"
#   end
# end
# ```
module Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  # Returns `true` if `self` is able to resolve a value from the provided *request* and *argument*.
  abstract def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata) : Bool

  # Returns a value resolved from the provided *request* and *argument*.
  abstract def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata)
end
