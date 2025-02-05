require "./configurable_view_handler_interface"

ADI.bind format_handlers : Array(Athena::Framework::View::FormatHandlerInterface), "!athena.format_handler"

@[ADI::AsAlias(ATH::View::ConfigurableViewHandlerInterface)]
@[ADI::AsAlias(ATH::View::ViewHandlerInterface)]
# Default implementation of `ATH::View::ConfigurableViewHandlerInterface`.
class Athena::Framework::View::ViewHandler
  include Athena::Framework::View::ConfigurableViewHandlerInterface

  @custom_handlers = Hash(String, ATH::View::ViewHandlerInterface::HandlerType).new

  @serialization_groups : Set(String)? = nil
  @serialization_version : SemanticVersion? = nil

  @empty_content_status : HTTP::Status
  @failed_validation_status : HTTP::Status
  @emit_nil : Bool

  def initialize(
    @url_generator : ART::Generator::Interface,
    @serializer : ASR::SerializerInterface,
    @request_store : ATH::RequestStore,
    format_handlers : Array(Athena::Framework::View::FormatHandlerInterface),
    @failed_validation_status : HTTP::Status = HTTP::Status::UNPROCESSABLE_ENTITY,
    @empty_content_status : HTTP::Status = HTTP::Status::NO_CONTENT,
    @emit_nil : Bool = false,
  )
    format_handlers.each do |format_handler|
      self.register_handler format_handler.format, format_handler
    end
  end

  # :inherit:
  def serialization_groups=(groups : Enumerable(String)) : Nil
    @serialization_groups = groups.to_set
  end

  # :inherit:
  def serialization_version=(version : String) : Nil
    self.serialization_version = SemanticVersion.parse version
  end

  # :inherit:
  def serialization_version=(version : SemanticVersion) : Nil
    @serialization_version = version
  end

  # :inherit:
  def emit_nil=(@emit_nil : Bool) : Nil
  end

  # :nodoc:
  #
  # This method is mainly for testing.
  def register_handler(format : String, &block : ATH::View::ViewHandlerInterface, ATH::ViewBase, ATH::Request, String -> ATH::Response) : Nil
    self.register_handler format, block
  end

  # :inherit:
  def register_handler(format : String, handler : ATH::View::ViewHandlerInterface::HandlerType) : Nil
    @custom_handlers[format] = handler
  end

  # :inherit:
  def supports?(format : String) : Bool
    # JSON is the only format supported via the serializer ATM.
    @custom_handlers.has_key?(format) || "json" == format
  end

  # :inherit:
  def handle(view : ATH::ViewBase, request : ATH::Request? = nil) : ATH::Response
    request = @request_store.request if request.nil?

    format = view.format || request.request_format

    unless self.supports? format
      raise ATH::Exception::NotAcceptable.new "The server is unable to return a response in the requested format: '#{format}'."
    end

    if custom_handler = @custom_handlers[format]?
      return custom_handler.call self, view, request, format
    end

    self.create_response view, request, format
  end

  # :inherit:
  def create_response(view : ATH::ViewBase, request : ATH::Request, format : String) : ATH::Response
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
  def create_redirect_response(view : ATH::ViewBase, location : String, format : String) : ATH::Response
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

  private def init_response(view : ATH::ViewBase, format : String) : ATH::Response
    content = nil

    # Skip serialization if the action's return type is explicitly `Nil`.
    if @emit_nil || view.return_type != Nil
      # TODO: Support Form typed views.

      # Fallback on `to_json` for non ASR::Serializable types.
      content = if data = view.serializable_data
                  data.to_json
                else
                  data = view.data

                  context = self.serialization_context view

                  # TODO: Implement some sort of Adapter system to convert ATH::View::Context
                  # into the serializer's required format. Just do that here for now.
                  athena_serializer_context = ASR::SerializationContext.new

                  context.emit_nil?.try do |en|
                    athena_serializer_context.emit_nil = en
                  end

                  context.version.try do |v|
                    athena_serializer_context.version = v
                  end

                  context.groups.try do |g|
                    athena_serializer_context.groups = g
                  end

                  context.exclusion_strategies.each do |s|
                    athena_serializer_context.add_exclusion_strategy s
                  end

                  serialized_data = @serializer.serialize data, format, athena_serializer_context

                  # If the serialized data is "null", but the data is not `nil`, assume this means the serializer component failed to serialize it,
                  # raise an error as it is likely the user forgot to include either `JSON::Serializable` or `ASR::Serializable`.
                  if "null" == serialized_data && !data.nil?
                    raise ATH::Exception::Logic.new "Failed to serialize response body. Did you forget to include either `JSON::Serializable` or `ASR::Serializable`?"
                  end

                  serialized_data
                end
    end

    response = view.response
    response.status = self.status view, content

    response.content = content unless content.nil?

    response
  end

  private def serialization_context(view : ATH::ViewBase) : ATH::View::Context
    context = view.context

    groups = context.groups

    if groups.nil? && (view_handler_groups = @serialization_groups) && !view_handler_groups.empty?
      context.groups = view_handler_groups
    end

    if context.version.nil? && (view_handler_version = @serialization_version)
      context.version = view_handler_version
    end

    if context.emit_nil?.nil? && (view_handler_emit_nil = @emit_nil)
      context.emit_nil = view_handler_emit_nil
    end

    # TODO: Set status code in context attributes if that's ever implemented.

    context
  end

  private def status(view : ATH::ViewBase, content : _) : HTTP::Status
    # TODO: Handle validating Form data.

    if status = view.status
      return status
    end

    content.nil? ? @empty_content_status : HTTP::Status::OK
  end
end
