@[ADI::Register(name: "parameter_resolver_request", tags: [{name: ATHR::Interface::TAG, priority: 50}])]
# Handles resolving a value for action parameters typed as `ATH::Request`.
#
# ```
# @[ARTA::Get("/")]
# def get_request_path(request : ATH::Request) : String
#   request.path
# end
# ```
struct Athena::Framework::Controller::ValueResolvers::Request
  include Athena::Framework::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata) : ATH::Request?
    return unless parameter.instance_of? ::ATH::Request

    request
  end
end
