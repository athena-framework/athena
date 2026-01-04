require "./value_resolvers/interface"
require "./argument_resolver_interface"

# The default implementation of `AHK::Controller::ArgumentResolverInterface`.
struct Athena::HTTPKernel::Controller::ArgumentResolver
  include Athena::HTTPKernel::Controller::ArgumentResolverInterface

  def initialize(@value_resolvers : Array(Athena::HTTPKernel::Controller::ValueResolvers::Interface)); end

  # :inherit:
  def get_arguments(request : AHTTP::Request, action : AHK::ActionBase) : Array
    action.resolve_arguments @value_resolvers, request
  end
end
