require "./view_handler_interface"

ADI.bind format_handlers : Array(Athena::Routing::View::FormatHandlerInterface), "!athena.format_handler"

@[ADI::Register]
class Athena::Routing::View::ViewHandler
  include Athena::Routing::View::ViewHandlerInterface

  # Only built in supported type at the moment is JSON.
  @formats : Set(String)

  @custom_handlers = Hash(String, ART::View::ViewHandlerInterface::HandlerType).new

  def initialize(
    @url_generator : ART::URLGeneratorInterface,
    @serializer : ASR::SerializerInterface,
    @request_store : ART::RequestStore,
    format_handlers : Array(Athena::Routing::View::FormatHandlerInterface),
    @formats : Set(String) = Set{"json"},
    @empty_content_status : HTTP::Status = HTTP::Status::NO_CONTENT,
    @serialize_null : Bool = false
  )
    format_handlers.each do |format_handler|
      self.register_handler format_handler.format, format_handler
    end
  end

  def register_handler(format : String, &block : ART::View::ViewHandlerInterface, ART::ViewBase, HTTP::Request, String -> ART::Response) : Nil
    self.register_handler format, block
  end

  def register_handler(format : String, handler : ART::View::ViewHandlerInterface::HandlerType) : Nil
    @custom_handlers[format] = handler
  end

  # :inherit:
  def supports?(format : String) : Bool
    @custom_handlers.has_key?(format) || @formats.includes?(format)
  end

  # :inherit:
  def handle(view : ART::ViewBase, request : HTTP::Request? = nil) : ART::Response
    request = @request_store.request if request.nil?

    format = view.format || request.request_format

    unless self.supports? format
      raise ART::Exceptions::NotAcceptable.new "The server is unable to return a response in the requested format: '#{format}'."
    end

    if custom_handler = @custom_handlers[format]?
      return custom_handler.call self, view, request, format
    end

    self.create_response view, request, format
  end

  # :inherit:
  def create_response(view : ART::ViewBase, request : HTTP::Request, format : String) : ART::Response
    route = view.route

    if location = (route ? @url_generator.generate(route, view.route_params, :absolute_url) : view.location)
      return self.create_redirect_response view, location, format
    end

    response = self.init_response view, format

    unless response.headers.has_key? "content-type"
      mime_type = request.attributes.get? "media_type", String

      if mime_type.nil?
        mime_type = request.mime_type format
      end

      response.headers["content-type"] = mime_type if mime_type
    end

    response
  end

  # :inherit:
  def create_redirect_response(view : ART::ViewBase, location : String, format : String) : ART::Response
    content = nil

    if (vs = view.status) && (vs.created? || vs.accepted?) && !view.data.nil?
      response = self.init_response view, format
    else
      response = view.response
    end

    response.status = self.status view, content
    response.headers["location"] = location

    response
  end

  private def init_response(view : ART::ViewBase, format : String) : ART::Response
    content = nil

    # Skip serialization if the action's return type is explicitly `Nil`.
    unless view.return_type == Nil
      # TODO: Support Form typed views.
      data = view.data

      context = view.context

      content = @serializer.serialize data, format, view.context
    end

    response = view.response
    response.status = self.status view, content

    response.content = content unless content.nil?

    response
  end

  private def status(view : ART::ViewBase, content : _) : HTTP::Status
    # TODO: Handle validating Form data.

    if status = view.status
      return status
    end

    content.nil? ? @empty_content_status : HTTP::Status::OK
  end
end
