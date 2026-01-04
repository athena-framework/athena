# Handles resolving a value for action parameters typed as [AHTTP::Request](/HTTP/Request).
#
# ```
# @[ARTA::Get("/")]
# def get_request_path(request : AHTTP::Request) : String
#   request.path
# end
# ```
struct Athena::HTTPKernel::Controller::ValueResolvers::Request
  include Athena::HTTPKernel::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata) : AHTTP::Request?
    return unless parameter.instance_of? ::AHTTP::Request

    request
  end
end
