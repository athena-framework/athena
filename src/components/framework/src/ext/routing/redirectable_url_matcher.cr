# :nodoc:
class Athena::Framework::Routing::RedirectableURLMatcher < Athena::Routing::Matcher::URLMatcher
  include ART::Matcher::RedirectableURLMatcherInterface

  def redirect(path : String, route : String, scheme : String? = nil) : Hash(String, String?)?
    {
      "_controller" => "Athena::Framework::Controller::Redirect#redirect_url",
      "_route"      => route,
      "path"        => path,
      "permanent"   => "true",
      "scheme"      => scheme,
    } of String => String?
  end
end
