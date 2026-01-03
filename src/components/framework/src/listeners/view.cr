class Athena::HTTPKernel::Action(ReturnType, ParameterTypeTuple, ParametersType) < Athena::HTTPKernel::ActionBase
  # This has to live here so the view is properly typed and not a union of all possible views.
  # Would be more ideal if we didn't have to monkey patch this in but :shrug:.
  protected def create_view(data : ReturnType) : ATH::View
    ATH::View(ReturnType).new data
  end

  protected def create_view(data : _) : NoReturn
    raise "BUG:  Invoked wrong `create_view` overload."
  end
end

@[ADI::Register]
# Listens on the `AHK::Events::View` event to convert a non [AHTTP::Response](/HTTP/Response) into an [AHTTP::Response](/HTTP/Response).
# Allows creating format agnostic controllers by allowing them to return format agnostic data that
# is later used to render the content in the expected format.
#
# See the [Getting Started](/getting_started/routing#content-negotiation) docs for more information.
struct Athena::Framework::Listeners::View
  def initialize(
    @view_handler : ATH::View::ViewHandlerInterface,
    @annotation_resolver : ATH::AnnotationResolver,
  ); end

  @[AEDA::AsEventListener(priority: 100)]
  def on_view(event : AHK::Events::View) : Nil
    request = event.request
    action = request.attributes.get "_action", AHK::ActionBase

    view = event.action_result

    unless view.is_a? ATH::View
      view = action.create_view view
    end

    if configuration = @annotation_resolver.action_annotations(request)[ATHA::View]?
      if (status = configuration.status) && (view.status.nil? || view.status.not_nil!.ok?)
        view.status = status
      end

      context = view.context

      if groups = configuration.serialization_groups
        if context_groups = context.groups
          context_groups.concat groups
        else
          context.groups = groups
        end
      end

      configuration.emit_nil.try do |emit_nil|
        context.emit_nil = emit_nil
      end
    end

    if view.format.nil?
      view.format = request.request_format
    end

    event.response = @view_handler.handle view, request
  end
end
