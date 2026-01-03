# Responsible for resolving the arguments that will be passed to a controller action.
#
# See the [Getting Started](/getting_started/middleware#argument-resolution) docs for more information.
module Athena::HTTPKernel::Controller::ArgumentResolverInterface
  # Returns an array of arguments resolved from the provided *request* for the given *action*.
  abstract def get_arguments(request : AHTTP::Request, action : AHK::ActionBase) : Array
end
