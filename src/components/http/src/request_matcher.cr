# Verifies that all [checks](/HTTP/RequestMatcher/Interface/) match against an `AHTTP::Request` instance.
#
# ```
# matcher = AHTTP::RequestMatcher.new(
#   AHTTP::RequestMatcher::Path.new(%r(/admin/foo)),
#   AHTTP::RequestMatcher::Method.new("GET"),
# )
#
# matcher.matches?(AHTTP::Request.new "GET", "/admin/foo")  # => true
# matcher.matches?(AHTTP::Request.new "POST", "/admin/foo") # => false
# ```
class Athena::HTTP::RequestMatcher
  # Represents a strategy that can be used to match an `AHTTP::Request`.
  # This interface can be used as a generic way to determine if some logic should be enabled for a given request based on the configured rules.
  module Interface
    # Decides whether the rule(s) implemented by the strategy matches the provided *request*.
    abstract def matches?(request : AHTTP::Request) : Bool
  end

  include Interface

  def self.new(*matchers : AHTTP::RequestMatcher::Interface)
    new matchers.map &.as(AHTTP::RequestMatcher::Interface)
  end

  def initialize(@matchers : Iterable(AHTTP::RequestMatcher::Interface)); end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    @matchers.all? &.matches? request
  end
end
