# :nodoc:
class Athena::Framework::Routing::RedirectableURLMatcher < Athena::Routing::Matcher::URLMatcher
  include ART::Matcher::RedirectableURLMatcherInterface

  def redirect(path : String, route : String, scheme : String? = nil) : ART::Parameters?
    ART::Parameters.new({
      "_controller" => "Athena::Framework::Controller::Redirect#redirect_url",
      "_action"     => ATH::Action.new(
        action: Proc(Tuple(AHTTP::Request, String, Bool, String?, Int32?, Int32?, Bool), AHTTP::RedirectResponse).new do |arguments|
          ADI.container.get(Athena::Framework::Controller::Redirect).redirect_url *arguments
        end,
        parameters: {
          ATH::Controller::ParameterMetadata(AHTTP::Request).new("request"),
          ATH::Controller::ParameterMetadata(String).new("path"),
          ATH::Controller::ParameterMetadata(Bool).new("permanent", true, false),
          ATH::Controller::ParameterMetadata(String?).new("scheme", true, nil),
          ATH::Controller::ParameterMetadata(Int32?).new("http_port", true, nil),
          ATH::Controller::ParameterMetadata(Int32?).new("https_port", true, nil),
          ATH::Controller::ParameterMetadata(Bool).new("keep_request_method", true, false),
        },
        annotation_configurations: ADI::AnnotationConfigurations.new,
        _controller: Athena::Framework::Controller::Redirect,
        _return_type: AHTTP::RedirectResponse,
      ),
      "_route"    => route,
      "path"      => path,
      "permanent" => "true",
      "scheme"    => scheme,
    })
  end
end
