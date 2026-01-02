# :nodoc:
class Athena::Framework::Routing::RedirectableURLMatcher < Athena::Routing::Matcher::URLMatcher
  include ART::Matcher::RedirectableURLMatcherInterface

  def redirect(path : String, route : String, scheme : String? = nil) : ART::Parameters?
    ART::Parameters.new({
      "_controller" => "Athena::Framework::Controller::Redirect#redirect_url",
      "_route"      => route,
      "path"        => path,
      "permanent"   => "true",
      "scheme"      => scheme,
    })
  end
end
