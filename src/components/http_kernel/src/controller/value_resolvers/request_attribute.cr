# Handles resolving a value that is stored in the request's [AHTTP::Request#attributes](/HTTP/Request/#Athena::HTTP::Request#attributes).
# This includes any path/query parameters, custom values stored via an event listener, or extra `defaults` stored within the routing annotation.
#
# ```
# @[ARTA::Get("/{id}")]
# def get_id(id : Int32) : Int32
#   id
# end
# ```
struct Athena::HTTPKernel::Controller::ValueResolvers::RequestAttribute
  include Athena::HTTPKernel::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata)
    return unless request.attributes.has? parameter.name

    value = request.attributes.get parameter.name

    parameter.type.from_parameter value
  rescue ex : ArgumentError
    # Catch type cast errors and bubble it up as a BadRequest
    raise AHK::Exception::BadRequest.new "Parameter '#{parameter.name}' with value '#{value}' could not be converted into a valid '#{parameter.type}'.", cause: ex
  end
end
