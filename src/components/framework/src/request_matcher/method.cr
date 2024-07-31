# Checks if the `ATH::Request#method` is allowed.
struct Athena::Framework::RequestMatcher::Method
  include Interface

  @methods : Array(String)

  def self.new(*methods : String)
    new methods.to_a
  end

  def initialize(@methods : Array(String))
    methods.map! &.upcase
  end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    return false if @methods.empty?

    @methods.includes? request.method
  end
end
