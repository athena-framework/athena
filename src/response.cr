abstract struct Writer
  def write(output : IO, & : IO -> Nil) : Nil
  end
end

# Default behavior of just yielding the output to the block,
# I.e. the proc writes directly to the response IO
struct PassThroughWriter < Writer
  def write(output : IO, & : IO -> Nil)
    yield output
  end
end

# Represents an HTTP response that should be returned to the client.
#
# The values on `self` are applied to the actual `HTTP::Server::Response` once the request is handled.
class Athena::Routing::Response
  getter content_callback : Proc(IO, Nil)

  setter writer : Writer = PassThroughWriter.new

  # The `HTTP::Status` of `self.`
  getter status : HTTP::Status

  # The response headers on `self.`
  getter headers : HTTP::Headers

  def self.new(status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers = HTTP::Headers.new, &block : IO -> Nil)
    new block, status, headers
  end

  def initialize(content : String? = nil, status : HTTP::Status | Int32 = HTTP::Status::OK, @headers : HTTP::Headers = HTTP::Headers.new)
    @status = HTTP::Status.new status
    @content_callback = Proc(IO, Nil).new { |io| io.print content }
  end

  def initialize(@content_callback : Proc(IO, Nil), status : HTTP::Status | Int32 = HTTP::Status::OK, @headers : HTTP::Headers = HTTP::Headers.new)
    @status = HTTP::Status.new status
  end

  # Writes `#content_callback` to the provided *io*.
  def write(output : IO) : Nil
    @writer.write(output) do |writer_io|
      @content_callback.call writer_io
    end
  end

  def content=(@content_callback : Proc(IO, Nil)); end

  def content=(content : String? = nil) : Nil
    self.content = Proc(IO, Nil).new { |io| io.print content }
  end

  # Returns the content of `self` as a `String`.
  def content : String
    String.build do |io|
      write io
    end
  end

  def status=(code : HTTP::Status | Int32) : Nil
    @status = HTTP::Status.new code
  end
end
