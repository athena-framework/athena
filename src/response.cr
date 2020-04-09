# Represents an HTTP response that should be returned to the client.
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
  # require "gzip"
  #
  # # Define a custom writer to gzip the response
  # struct GzipWriter < ART::Response::Writer
  #   def write(output : IO, & : IO -> Nil) : Nil
  #     Gzip::Writer.open(output) do |gzip_io|
  #       yield gzip_io
  #     end
  #   end
  # end
  #
  # @[ADI::Register(tags: ["athena.event_dispatcher.listener"])]
  # # Next define a new event listener to handle applying this writer
  # struct CompressionListener
  #   include AED::EventListenerInterface
  #   include ADI::Service
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

  # The `HTTP::Status` of `self.`
  getter status : HTTP::Status

  # The response headers on `self.`
  getter headers : HTTP::Headers

  @content_callback : Proc(IO, Nil)
  @content_string : String? = nil

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

  # Writes content of `self` to the provided *output*.
  #
  # Can be customized via a `ART::Response::Writer`.
  def write(output : IO) : Nil
    @writer.write(output) do |writer_io|
      @content_callback.call writer_io
    end
  end

  def content=(@content_callback : Proc(IO, Nil))
    # Reset the content string if the content changes
    @content_string = nil
  end

  def content=(content : String? = nil) : Nil
    self.content = Proc(IO, Nil).new { |io| io.print content }
  end

  # Returns the content of `self` as a `String`.
  #
  # The content string is cached to avoid unnecessarily regenerating
  # the same string multiple times.
  #
  # The cached string is cleared when changing the content via `#content=`.
  def content : String
    @content_string ||= String.build do |io|
      write io
    end
  end

  # The `HTTP::Status` of `self.`
  def status=(code : HTTP::Status | Int32) : Nil
    @status = HTTP::Status.new code
  end
end
