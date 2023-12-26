# Checks if the `ATH::Request#path` matches the allowed pattern.
struct Athena::Framework::RequestMatcher::Path
  include Interface

  def initialize(@regex : Regex); end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    URI.decode(request.path).matches? @regex
  end
end
