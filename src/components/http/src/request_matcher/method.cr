# Checks if the `AHTTP::Request#method` is allowed.
struct Athena::HTTP::RequestMatcher::Method
  include Interface

  @methods : Array(String)

  def self.new(*methods : String)
    new methods.to_a
  end

  def initialize(@methods : Array(String))
    methods.map! &.upcase
  end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    return false if @methods.empty?

    @methods.includes? request.method
  end
end
