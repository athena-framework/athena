@[ADI::Register]
# Listens on the `ART::Events::View` event to convert a non `ART::Response` into an `ART::Response`.
# Allows creating format agnostic controllers by allowing them to return format agnostic data that
# is later used to render the content in the expected format.
#
# See the [negotiation](/components/negotiation) component for more information.
struct Athena::Routing::Listeners::View
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{ART::Events::View => 100}
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
