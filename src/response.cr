class Athena::Routing::Response
  getter io : IO
  property status : HTTP::Status
  getter headers : HTTP::Headers

  def initialize(@io : IO, @status : HTTP::Status, @headers : HTTP::Headers = HTTP::Headers.new); end

  def self.new(content : String? = "", status : HTTP::Status = HTTP::Status::OK, headers : HTTP::Headers = HTTP::Headers.new)
    new IO::Memory.new(content || ""), status, headers
  end

  def self.new(content : String? = "", status : Int32 = 200, headers : HTTP::Headers = HTTP::Headers.new)
    new content, HTTP::Status.new(status), headers
  end
end
