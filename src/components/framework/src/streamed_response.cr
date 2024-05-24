# Represents an `ATH::Response` whose content should be streamed to the client as opposed to being written all at once.
# This can be useful in cases where the response content is too large to fit into memory.
#
# The content is stored in a proc that gets called when `self` is being written to the response IO.
# How the output gets written can be customized via an `ATH::Response::Writer`.
class Athena::Framework::StreamedResponse < Athena::Framework::Response
  @streamed : Bool = false

  # Creates a new response with optional *status*, and *headers* arguments.
  #
  # The block is captured and called when `self` is being written to the response's `IO`.
  # This can be useful to reduce memory overhead when needing to return large responses.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/users")]
  #   def users : ATH::Response
  #     ATH::StreamedResponse.new headers: HTTP::Headers{"content-type" => "application/json; charset=utf-8"} do |io|
  #       User.all.to_json io
  #     end
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /users # => [{"id":1,...},...]
  # ```
  def self.new(status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers | ATH::Response::Headers = ATH::Response::Headers.new, &block : IO -> Nil)
    new block, status, headers
  end

  # Creates a new response with the provided *callback* and optional *status*, and *headers* arguments.
  #
  # The proc is called when `self` is being written to the response's `IO`.
  def initialize(@callback : Proc(IO, Nil), status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers | ATH::Response::Headers = ATH::Response::Headers.new)
    # Manually add `transfer-encoding: chunked` so `ART::Response#prepare` knows how to properly handle this type of response.
    super nil, status, headers.merge!({"transfer-encoding" => "chunked"})
  end

  # Updates the callback of `self`.
  def content=(@callback : Proc(IO, Nil))
  end

  # :nodoc:
  def content=(content : String?) : Nil
    raise "The content cannot be set on a StreamedResponse instance." unless content.nil?

    @streamed = true
  end

  protected def write(output : IO) : Nil
    return if @streamed

    @streamed = true

    @writer.write(output) do |writer_io|
      @callback.call writer_io
    end
  end
end
