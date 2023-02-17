# Represents an `HTTP` response that should be returned to the client.
#
# Contains the content, status, and headers that should be applied to the actual `HTTP::Server::Response`.
# This type is used to allow the content, status, and headers to be mutated by `ATH::Listeners` before being returned to the client.
#
# The `#content` is written all at once to the server response's `IO`.
class Athena::Framework::Response
  # Determines how the content of an `ATH::Response` will be written to the requests' response `IO`.
  #
  # By default the content is written directly to the requests' response `IO` via `ATH::Response::DirectWriter`.
  # However, custom writers can be implemented to customize that behavior. The most common use case would be for compression.
  #
  # Writers can also be defined as services and injected into a listener if they require additional external dependencies.
  #
  # ### Example
  #
  # ```
  # require "athena"
  # require "compress/gzip"
  #
  # # Define a custom writer to gzip the response
  # struct GzipWriter < ATH::Response::Writer
  #   def write(output : IO, & : IO -> Nil) : Nil
  #     Compress::Gzip::Writer.open(output) do |gzip_io|
  #       yield gzip_io
  #     end
  #   end
  # end
  #
  # # Define a new event listener to handle applying this writer
  # @[ADI::Register]
  # struct CompressionListener
  #   include AED::EventListenerInterface
  #
  #   @[AEDA::AsEventListener(priority: -256)]
  #   def on_response(event : ATH::Events::Response) : Nil
  #     # If the request supports gzip encoding
  #     if event.request.headers.includes_word?("accept-encoding", "gzip")
  #       # Change the `ATH::Response` object's writer to be our `GzipWriter`
  #       event.response.writer = GzipWriter.new
  #
  #       # Set the encoding of the response to gzip
  #       event.response.headers["content-encoding"] = "gzip"
  #     end
  #   end
  # end
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/users")]
  #   def users : Array(User)
  #     User.all
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /users # => [{"id":1,...},...] (gzipped)
  # ```
  abstract struct Writer
    # Accepts an *output* `IO` that the content of the response should be written to.
    abstract def write(output : IO, & : IO -> Nil) : Nil
  end

  # The default `ATH::Response::Writer` for an `ATH::Response`.
  #
  # Writes directly to the *output* `IO`.
  struct DirectWriter < Writer
    # :inherit:
    #
    # The *output* `IO` is yielded directly.
    def write(output : IO, & : IO -> Nil) : Nil
      yield output
    end
  end

  # See `ATH::Response::Writer`.
  setter writer : ATH::Response::Writer = ATH::Response::DirectWriter.new

  # Returns the `HTTP::Status` of this response.
  getter status : HTTP::Status

  # Returns the character set this response is encoded as.
  property charset : String = "UTF-8"

  # Returns the response headers of this response.
  getter headers : ATH::Response::Headers

  # Returns the contents of this response.
  getter content : String

  # Creates a new response with optional *content*, *status*, and *headers* arguments.
  def initialize(content : String? = nil, status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers | ATH::Response::Headers = ATH::Response::Headers.new)
    @content = content || ""
    @status = HTTP::Status.new status
    @headers = ATH::Response::Headers.new headers
  end

  # Sets the response content.
  def content=(content : String?)
    @content = content || ""
  end

  # Sends `self` to the client based on the provided *context*.
  #
  # How the content gets written can be customized via an `ATH::Response::Writer`.
  def send(request : ATH::Request, response : HTTP::Server::Response) : Nil
    # Ensure the response is valid.
    self.prepare request

    # Apply the `ATH::Response` to the actual `HTTP::Server::Response` object.
    response.headers.merge! @headers
    response.status = @status

    @headers.cookies.each do |c|
      response.cookies << c
    end

    # Write the response content last on purpose.
    # See https://github.com/crystal-lang/crystal/issues/8712
    self.write response

    # Close the response.
    response.close
  end

  # Sets the `HTTP::Status` of this response.
  def status=(code : HTTP::Status | Int32) : Nil
    @status = HTTP::Status.new code
  end

  # :nodoc:
  #
  # Do any preparation to ensure the response is RFC compliant.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def prepare(request : ATH::Request) : Nil
    # Set the content length if not already manually set
    @headers["content-length"] = @content.size unless @headers.has_key? "content-length"

    if @status.informational? || @status.no_content? || @status.not_modified?
      self.content = nil
      @headers.delete "content-type"
      @headers.delete "content-length"
    else
      # Set `content-type` based on the request's format.
      unless @headers.has_key? "content-type"
        if (format = request.request_format nil) && (mime_type = request.mime_type format)
          @headers["content-type"] = mime_type
        end
      end

      # Add charset to `text/` based content types.
      charset = self.charset

      if (content_type = @headers["content-type"]?) && content_type.starts_with?("text/") && !content_type.includes?("charset")
        @headers["content-type"] = "#{content_type}; charset=#{charset}"
      end

      @headers.delete "content-length" if @headers.has_key? "transfer-encoding"

      if "HEAD" == request.method
        # See https://tools.ietf.org/html/rfc2616#section-14.13.
        length = @headers["content-length"]?
        self.content = nil
        @headers["content-length"] = length if length
      end
    end

    if "HTTP/1.0" == request.version && @headers.has_cache_control_directive?("no-cache")
      @headers["pragma"] = "no-cache"
      @headers["expires"] = "-1"
    end
  end

  # Marks `self` as "public".
  #
  # Adds the `public` `cache-control` directive and removes the `private` directive.
  def set_public : Nil
    @headers.add_cache_control_directive "public"
    @headers.remove_cache_control_directive "private"
  end

  # Returns the value of the `etag` header if set, otherwise `nil`.
  def etag : String?
    @headers["etag"]?
  end

  # Updates the `etag` header to the provided, optionally *weak*, *etag*.
  # Removes the header if *etag* is `nil`.
  def set_etag(etag : String? = nil, weak : Bool = false) : Nil
    if etag.nil?
      return @headers.delete "etag"
    end

    unless etag.includes? '"'
      etag = %("#{etag}")
    end

    @headers["etag"] = "#{weak ? "W/" : ""}#{etag}"
  end

  # Returns a `Time`representing the `last-modified` header if set, otherwise `nil`.
  def last_modified : Time?
    if header = @headers["last-modified"]?
      HTTP.parse_time header
    end
  end

  # Updates the `last-modified` header to the provided *time*.
  # Removes the header if *time* is `nil`.
  def last_modified=(time : Time? = nil) : Nil
    if time.nil?
      return @headers.delete "last-modified"
    end

    @headers["last-modified"] = HTTP.format_time time
  end

  protected def write(output : IO) : Nil
    @writer.write(output, &.print(@content))
  end
end
