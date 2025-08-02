# :nodoc:
struct Athena::Framework::Listeners::File
  protected def initialize(@file_parser : ATH::FileParser); end

  @[AEDA::AsEventListener]
  def on_request(event : ATH::Events::Request) : Nil
    return unless event.request.headers["content-type"]?.try &.starts_with? "multipart/form-data"

    @file_parser.parse event.request
  end

  @[AEDA::AsEventListener]
  def on_terminate(event : ATH::Events::Terminate) : Nil
    @file_parser.clear
  end
end
