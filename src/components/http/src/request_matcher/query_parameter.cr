# Checks the presence of HTTP query parameters in an `AHTTP::Request`.
struct Athena::HTTP::RequestMatcher::QueryParameter
  include Interface

  @parameters : Array(String)

  def self.new(*parameters : String)
    new parameters.to_a
  end

  def initialize(@parameters : Array(String)); end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    return true if @parameters.empty?

    query_params = request.query_params

    @parameters.each do |parameter|
      return false unless query_params.has_key? parameter
    end

    true
  end
end
