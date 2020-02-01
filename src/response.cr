# Represents an HTTP response that should be returned to the client.
#
# The values on `self` are applied to the actual `HTTP::Server::Response` once the request is handled.
class Athena::Routing::Response
  # The `IO` that `self`'s content is written to.
  #
  # Can be replaced, such as for compressing the response content.
  property io : IO

  # The `HTTP::Status` of `self.`
  property status : HTTP::Status

  # The response headers on `self.`
  getter headers : HTTP::Headers

  def initialize(content : String? = "", @status : HTTP::Status = HTTP::Status::OK, @headers : HTTP::Headers = HTTP::Headers.new)
    @io = IO::Memory.new(content || "")
  end

  def self.new(content : String? = "", status : Int32 = 200, headers : HTTP::Headers = HTTP::Headers.new)
    new content, HTTP::Status.new(status), headers
  end
end
