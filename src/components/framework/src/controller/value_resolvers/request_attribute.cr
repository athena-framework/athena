@[ADI::Register(name: "parameter_resolver_request_attribute", tags: [{name: ATHR::Interface::TAG, priority: 100}])]
# Handles resolving a value that is stored in the request's `ATH::Request#attributes`.
# This includes any path/query parameters, custom types values stored via an `AED::EventListenerInterface`, or extra `defaults` stored within the routing annotation.
#
# ```
# @[ARTA::Get("/{id}")]
# def get_id(id : Int32) : Int32
#   id
# end
# ```
struct Athena::Framework::Controller::ValueResolvers::RequestAttribute
  include Athena::Framework::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    return unless request.attributes.has? parameter.name

    value = request.attributes.get parameter.name

    parameter.type.from_parameter value
  rescue ex : ArgumentError
    # Catch type cast errors and bubble it up as a BadRequest
    raise ATH::Exceptions::BadRequest.new "Parameter '#{parameter.name}' with value '#{value}' could not be converted into a valid '#{parameter.type}'.", cause: ex
  end
end
