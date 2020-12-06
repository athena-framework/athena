class Athena::Routing::StreamedResponse < Athena::Routing::Response
  @streamed : Bool = false

  # Creates a new response with optional *status*, and *headers* arguments.
  #
  # The block is captured and called when `self` is being written to the response `IO`.
  # This can be useful to reduce memory overhead when needing to return large responses.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ART::Controller
  #   @[ART::Get("/users")]
  #   def users : ART::Response
  #     ART::StreamedResponse.new headers: HTTP::Headers{"content-type" => "application/json; charset=UTF-8"} do |io|
  #       User.all.to_json io
  #     end
  #   end
  # end
  #
  # ART.run
  #
  # # GET /users # => [{"id":1,...},...]
  # ```
  def self.new(status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers = HTTP::Headers.new, &block : IO -> Nil)
    new block, status, headers
  end

  # Creates a new response with the provided *content_callback* and optional *status*, and *headers* arguments.
  #
  # The proc is called when `self` is being written to the response IO.
  def initialize(@callback : Proc(IO, Nil), status : HTTP::Status | Int32 = HTTP::Status::OK, headers : HTTP::Headers = HTTP::Headers.new)
    super nil, status, headers
  end

  # Writes content of `self` to the provided *output*.
  #
  # How the output gets written can be customized via an `ART::Response::Writer`.
  def write(output : IO) : Nil
    return if @streamed

    @streamed = true

    @writer.write(output) do |writer_io|
      @callback.call writer_io
    end
  end

  # Updates the content of `self`.
  def content=(@callback : Proc(IO, Nil))
  end

  # :ditto:
  def content=(content : String?) : Nil
    raise "The content cannot be set on a StreamedResponse instance." unless content.nil?

    @streamed = true
  end
end
