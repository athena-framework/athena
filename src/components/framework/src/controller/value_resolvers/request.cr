@[ADI::Register(name: "parameter_resolver_request", tags: [{name: ATHR::Interface::TAG, priority: 50}])]
# Handles resolving a value for action parameters typed as `AHTTP::Request`.
#
# ```
# @[ARTA::Get("/")]
# def get_request_path(request : AHTTP::Request) : String
#   request.path
# end
# ```
struct Athena::Framework::Controller::ValueResolvers::Request
  include Athena::Framework::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : ATH::Controller::ParameterMetadata) : AHTTP::Request?
    return unless parameter.instance_of? ::AHTTP::Request

    request
  end
end
