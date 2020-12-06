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
  #   @[ART::Get("/users")]
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

  @[Deprecated("Use `ART::StreamedResponse.new` instead. This will be removed in Athena `0.13.0`.")]
  def self.new(status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers = HTTP::Headers.new, &block : IO -> Nil) : ART::StreamedResponse
    ART::StreamedResponse.new block, status, headers
  end

  # Creates a new response with optional *content*, *status*, and *headers* arguments.
  def initialize(content : String? = nil, status : HTTP::Status | Int32 = HTTP::Status::OK, @headers : HTTP::Headers = HTTP::Headers.new)
    @content = content || ""
    @status = HTTP::Status.new status
  end

  # Sets the response content.
  def content=(content : String?)
    @content = content || ""
  end

  # Sets the status of this response.
  def status=(code : HTTP::Status | Int32) : Nil
    @status = HTTP::Status.new code
  end

  # :nodoc:
  #
  # Do any preparation to ensure the response is RFC compliant.
  def prepare(request : HTTP::Request) : Nil
    if @status.informational? || @status.no_content? || @status.not_modified?
      self.content = nil
      @headers.delete "content-type"
      @headers.delete "content-length"
    else
      @headers.delete "content-length" if @headers.has_key? "transfer-encoding"
      self.content = nil if "HEAD" == request.method
    end

    if "HTTP/1.0" == request.version && @headers["cache-control"]?.try &.includes? "no-cache"
      @headers["pragma"] = "no-cache"
      @headers["expires"] = "-1"
    end
  end

  # Writes the `#content` to the provided *output*.
  #
  # How the output gets written can be customized via an `ART::Response::Writer`.
  def write(output : IO) : Nil
    @writer.write(output) do |writer_io|
      writer_io.print @content
    end
  end
end
