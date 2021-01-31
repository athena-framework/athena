# Represents an `HTTP` response that should be returned to the client.
#
# Contains the content, status, and headers that should be applied to the actual `HTTP::Server::Response`.
# This type is used to allow the content, status, and headers to be mutated by `ART::Listeners` before being returned to the client.
#
# The `#content` is written all at once to the server response's `IO`.
class Athena::Routing::Response
  # Determines how the content of an `ART::Response` will be written to the requests' response `IO`.
  #
  # By default the content is written directly to the requests' response `IO` via `ART::Response::DirectWriter`.
  # However, custom writers can be implemented to customize that behavior.  The most common use case would be for compression.
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
  # struct GzipWriter < ART::Response::Writer
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
  #   def self.subscribed_events : AED::SubscribedEvents
  #     AED::SubscribedEvents{
  #       ART::Events::Response => -256, # Listen on the Response event with a very low priority
  #     }
  #   end
  #
  #   def call(event : ART::Events::Response, dispatcher : AED::EventDispatcherInterface) : Nil
  #     # If the request supports gzip encoding
  #     if event.request.headers.includes_word?("accept-encoding", "gzip")
  #       # Change the `ART::Response` object's writer to be our `GzipWriter`
  #       event.response.writer = GzipWriter.new
  #
  #       # Set the encoding of the response to gzip
  #       event.response.headers["content-encoding"] = "gzip"
  #     end
  #   end
  # end
  #
  # class ExampleController < ART::Controller
  #   @[ARTA::Get("/users")]
  #   def users : Array(User)
  #     User.all
  #   end
  # end
  #
  # ART.run
  #
  # # GET /users # => [{"id":1,...},...] (gzipped)
  # ```
  abstract struct Writer
    # Accepts an *output* `IO` that the content of the response should be written to.
    abstract def write(output : IO, & : IO -> Nil) : Nil
  end

  # The default `ART::Response::Writer` for an `ART::Response`.
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

  # See `ART::Response::Writer`.
  setter writer : ART::Response::Writer = ART::Response::DirectWriter.new

  # Returns the `HTTP::Status` of this response.
  getter status : HTTP::Status

  # Returns the response headers of this response.
  getter headers : HTTP::Headers

  # Returns the contents of this response.
  getter content : String

  # Creates a new response with optional *content*, *status*, and *headers* arguments.
  def initialize(content : String? = nil, status : HTTP::Status | Int32 = HTTP::Status::OK, @headers : HTTP::Headers = HTTP::Headers.new)
    @content = content || ""
    @status = HTTP::Status.new status
  end

  # Sets the response content.
  def content=(content : String?)
    @content = content || ""
  end

  # Sends `self` to the client based on the provided *context*.
  #
  # How the content gets written can be customized via an `ART::Response::Writer`.
  def send(context : HTTP::Server::Context) : Nil
    # Ensure the response is valid.
    self.prepare context.request

    # Apply the `ART::Response` to the actual `HTTP::Server::Response` object.
    context.response.headers.merge! @headers
    context.response.status = @status

    # Write the response content last on purpose.
    # See https://github.com/crystal-lang/crystal/issues/8712
    self.write context.response

    # Close the response.
    context.response.close
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
  def prepare(request : HTTP::Request) : Nil
    # TODO: Move this logic directly into HTTP::Headers.
    # See https://tools.ietf.org/html/rfc2616#section-14.18.
    if !@headers.has_key?("date") && !@status.continue? && !@status.switching_protocols?
      @headers["date"] = Time::Format::HTTP_DATE.format(Time.utc)
    end

    # Set sensible default cache-control header.
    unless @headers.has_key? "cache-control"
      @headers.add_cache_control_directive "private"

      if @headers.has_key?("last-modified") || @headers.has_key?("expires")
        @headers.add_cache_control_directive "must-revalidate"
      else
        @headers.add_cache_control_directive "no-cache"
      end
    end

    if @status.informational? || @status.no_content? || @status.not_modified?
      self.content = nil
      @headers.delete "content-type"
      @headers.delete "content-length"
    else
      @headers.delete "content-length" if @headers.has_key? "transfer-encoding"
      self.content = nil if "HEAD" == request.method
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
      Time::Format::HTTP_DATE.parse header
    end
  end

  # Updates the `last-modified` header to the provided *time*.
  # Removes the header if *time* is `nil`.
  def last_modified=(time : Time? = nil) : Nil
    if time.nil?
      return @headers.delete "last-modified"
    end

    @headers["last-modified"] = Time::Format::HTTP_DATE.format(time)
  end

  protected def write(output : IO) : Nil
    @writer.write(output) do |writer_io|
      writer_io.print @content
    end
  end
end
