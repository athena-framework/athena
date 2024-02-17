# Verifies that all [checks][ATH::RequestMatcher::Interface] match against an `ATH::Request` instance.
#
# ```
# matcher = ATH::RequestMatcher.new(
#   ATH::RequestMatcher::Path.new(%r(/admin/foo)),
#   ATH::RequestMatcher::Method.new("GET"),
# )
#
# matcher.matches?(ATH::Request.new "GET", "/admin/foo")  # => true
# matcher.matches?(ATH::Request.new "POST", "/admin/foo") # => false
# ```
class Athena::Framework::RequestMatcher
  # Represents a strategy that can be used to match an `ATH::Request`.
  # This interface can be used as a generic way to determine if some logic should be enabled for a given request based on the configured rules.
  module Interface
    # Decides whether the rule(s) implemented by the strategy matches the provided *request*.
    abstract def matches?(request : ATH::Request) : Bool
  end

  include Interface

  def self.new(*matchers : ATH::RequestMatcher::Interface)
    new matchers.map &.as(ATH::RequestMatcher::Interface)
  end

  def initialize(@matchers : Iterable(ATH::RequestMatcher::Interface)); end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    @matchers.all? &.matches? request
  end
end
