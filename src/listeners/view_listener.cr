@[ADI::Register]
struct Athena::Routing::Listeners::View
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::View => 100,
    }
  end

  def initialize(@view_handler : ART::View::ViewHandlerInterface); end

  def call(event : ART::Events::View, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request
    action = request.action

    view = event.action_result

    unless view.is_a? ART::View
      view = action.create_view view
    end

    if configuration = event.request.action.annotation_configurations[ARTA::View]?
      if (status = configuration.status) && (view.status.nil? || view.status.not_nil!.ok?)
        view.status = status
      end

      context = view.context

      # context.emit_nil = configuration.emit_nil

      if groups = configuration.serialization_groups
        if context_groups = context.groups
          context_groups.concat groups
        else
          context.groups = groups
        end
      end
    end

    if view.format.nil?
      view.format = request.request_format
    end

    event.response = @view_handler.handle view, request
  end
end
