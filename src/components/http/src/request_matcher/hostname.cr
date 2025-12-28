# Checks if the `AHTTP::Request#hostname` matches the allowed pattern.
struct Athena::HTTP::RequestMatcher::Hostname
  include Interface

  def initialize(regex : Regex)
    @regex = Regex.new regex.source, :ignore_case
  end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    return false unless hostname = request.host

    hostname.matches? @regex
  end
end
