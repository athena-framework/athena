# :nodoc:
module Athena::Routing::Matcher::RedirectableURLMatcherInterface
  abstract def redirect(path : String, route : String, scheme : String? = nil) : Hash(String, String?)?
end
