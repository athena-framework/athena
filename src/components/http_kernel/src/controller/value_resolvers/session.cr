# Handles resolving a value for action parameters typed as `AHTTP::Session`, if the request has a session.
#
# ```
# @[ARTA::Get("/")]
# def visits(session : AHTTP::Session) : Int32
#   visits = (session.get?("visits", Int32) || 0) + 1
#   session.set "visits", visits
#
#   visits
# end
# ```
class Athena::HTTPKernel::Controller::ValueResolvers::Session
  include Athena::HTTPKernel::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata) : AHTTP::Session?
    return unless parameter.instance_of? AHTTP::Session
    return unless request.has_session?
    return if request.attributes.has? parameter.name

    request.session
  end
end
