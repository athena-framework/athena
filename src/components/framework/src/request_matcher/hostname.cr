# Checks if the `ATH::Request#hostname` matches the allowed pattern.
struct Athena::Framework::RequestMatcher::Hostname
  include Interface

  def initialize(regex : Regex)
    @regex = Regex.new regex.source, :ignore_case
  end

  # :inherit:
  def matches?(request : ATH::Request) : Bool
    return false unless hostname = request.host

    hostname.matches? @regex
  end
end
