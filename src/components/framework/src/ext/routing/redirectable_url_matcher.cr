# :nodoc:
class Athena::Framework::Routing::RedirectableURLMatcher < Athena::Routing::Matcher::URLMatcher
  include ART::Matcher::RedirectableURLMatcherInterface

  def redirect(path : String, route : String, scheme : String? = nil) : ART::Parameters?
    ART::Parameters.new({
      "_controller" => "Athena::Framework::Controller::Redirect#redirect_url",
      "_action"     => AHK::Action.new(
        action: Proc(Tuple(AHTTP::Request, String, Bool, String?, Int32?, Int32?, Bool), AHTTP::RedirectResponse).new do |arguments|
          ADI.container.get(Athena::Framework::Controller::Redirect).redirect_url *arguments
        end,
        parameters: {
          AHK::Controller::ParameterMetadata(AHTTP::Request).new("request"),
          AHK::Controller::ParameterMetadata(String).new("path"),
          AHK::Controller::ParameterMetadata(Bool).new("permanent", true, false),
          AHK::Controller::ParameterMetadata(String?).new("scheme", true, nil),
          AHK::Controller::ParameterMetadata(Int32?).new("http_port", true, nil),
          AHK::Controller::ParameterMetadata(Int32?).new("https_port", true, nil),
          AHK::Controller::ParameterMetadata(Bool).new("keep_request_method", true, false),
        },
        _return_type: AHTTP::RedirectResponse,
      ),
      "_route"    => route,
      "path"      => path,
      "permanent" => "true",
      "scheme"    => scheme,
    })
  end
end
