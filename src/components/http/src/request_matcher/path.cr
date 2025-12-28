# Checks if the `AHTTP::Request#path` matches the allowed pattern.
struct Athena::HTTP::RequestMatcher::Path
  include Interface

  def initialize(@regex : Regex); end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    URI.decode(request.path).matches? @regex
  end
end
