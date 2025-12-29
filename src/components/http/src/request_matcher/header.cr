# Checks the presence of HTTP headers in an `AHTTP::Request`.
struct Athena::HTTP::RequestMatcher::Header
  include Interface

  @headers : Array(String)

  def self.new(*headers : String)
    new headers.to_a
  end

  def initialize(@headers : Array(String)); end

  # :inherit:
  def matches?(request : AHTTP::Request) : Bool
    return true if @headers.empty?

    headers = request.headers

    @headers.each do |header|
      return false unless headers.has_key? header
    end

    true
  end
end
