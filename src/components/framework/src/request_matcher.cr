# Verifies that all [checks][ATH::RequestMatcher::Interface] match against an `ATH::Request` instance.
#
# ```
# ```
class Athena::Framework::RequestMatcher
  module Interface
    abstract def matches?(request : ATH::Request) : Bool
  end

  include Interface

  def self.new(*matchers : ATH::RequestMatcher::Interface)
    new matchers.map &.as(ATH::RequestMatcher::Interface)
  end

  def initialize(@matchers : Iterable(ATH::RequestMatcher::Interface)); end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    @matchers.all? { |m| m.matches? request }
  end
end
