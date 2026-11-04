# Maps requests to the attribute they require, e.g. a role, via request matchers, see `ASEC::Firewall::AccessListener`.
#
# A request requires the attribute of the first request matcher matching it.
#
# ```
# access_map = ASEC::AccessMap.new
# access_map.add AHTTP::RequestMatcher::Path.new(%r(^/admin/login)), ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS
# access_map.add AHTTP::RequestMatcher::Path.new(%r(^/admin)), "ROLE_ADMIN"
# ```
class Athena::Security::AccessMap
  @map = [] of Tuple(AHTTP::RequestMatcher::Interface, String?)

  # Adds a rule for the requests matching the provided *request_matcher*, which require the provided *attribute*.
  #
  # A `nil` *attribute* requires nothing, e.g. to exclude some requests from a later rule.
  def add(request_matcher : AHTTP::RequestMatcher::Interface, attribute : String? = nil) : Nil
    @map << {request_matcher, attribute}
  end

  # Returns the attribute required by the first rule matching the provided *request*, or `nil` if it requires none.
  def attribute(request : AHTTP::Request) : String?
    @map.each do |request_matcher, attribute|
      return attribute if request_matcher.matches? request
    end

    nil
  end
end
