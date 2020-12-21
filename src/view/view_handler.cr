require "./view_handler_interface"

@[ADI::Register]
class Athena::Routing::View::ViewHandler
  include Athena::Routing::View::ViewHandlerInterface

  # Only built in supported type at the moment is JSON.
  @formats = Set{"json"}

  def initialize(
    @url_generator : ART::URLGeneratorInterface,
    @serializer : ASR::SerializerInterface,
    @request_store : ART::RequestStore,
    @failed_validation_status : HTTP::Status = HTTP::Status::UNPROCESSABLE_ENTITY,
    @empty_content_status : HTTP::Status = HTTP::Status::NO_CONTENT
  ); end

  # :inherit:
  def supports?(format : String) : Bool
    @formats.includes? format
  end

  # :inherit:
  def handle(view : ART::View, request : HTTP::Request? = nil) : ART::Response
    request = @request_store.request if request.nil?

    format = view.format || request.format

    unless self.supports? format
      raise ART::Exceptions::UnsupportedMediaType.new "Format '#{format}' has no built in handler.  A custom handler must be implemented."
    end

    self.create_response view, request, format
  end

  # :inherit:
  def create_response(view : ART::View, request : HTTP::Request, format : String) : ART::Response
    route = view.route

    location = route ? @url_generator.generate(route, view.route_parameters, :absolute_url) : view.location

    if location
      # return self.create_redirect_response view, location, format
    end

    response = self.init_response view, format
  end

  private def init_response(view : ART::View, format : String) : ART::Response
    content = nil

    unless view.data.nil?
      # TODO: Support Form typed views.
      data = view.data

      # TODO: Create correct serialization context
      content = @serializer.serialize data, format
    end

    response = view.response
    response.status = self.status_code view, content

    response.content = content unless content.nil?

    response
  end

  private def status_code(view : ART::View, content : _) : HTTP::Status
    # TODO: Handle validating Form data

    if status = view.status
      return status
    end

    content.nil? ? @empty_content_status : HTTP::Status::OK
  end
end
