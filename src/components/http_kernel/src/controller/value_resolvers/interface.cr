# Value resolvers handle resolving the argument(s) to pass to a controller action based on values stored within the [AHTTP::Request](/HTTP/Request), or some other source.
#
# Custom resolvers can be defined by creating a type that implements this interface.
# The first resolver to return a value wins and no other resolvers will be executed for that particular parameter.
# The resolver should return `nil` to denote no value could be resolved, such as if the parameter is of the wrong type, does not have a specific annotation applied, or anything else that can be deduced from either parameter.
# If no resolver is able to resolve a value for a specific parameter, an error is thrown and processing of the request ceases.
module Athena::HTTPKernel::Controller::ValueResolvers::Interface
  # Returns a value resolved from the provided *request* and *parameter* if possible, otherwise returns `nil` if no parameter could be resolved.
  abstract def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata)
end
