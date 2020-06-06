# Responsible for resolving the arguments that will be passed to a controller action.
module Athena::Routing::Arguments::ArgumentResolverInterface
  # Returns an array of arguments resolved from the provided *request* for the given *route*.
  abstract def get_arguments(request : HTTP::Request, route : ART::Action) : Array
end
