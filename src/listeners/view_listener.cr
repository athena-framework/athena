@[ADI::Register]
# The view listener attempts to resolve a non `ART::Response` into an `ART::Response`.
# Currently this is achieved by JSON serializing the controller action's resulting value;
# either via `Object#to_json` or `ASR::Serializer`, depending on what type the resulting value is.
#
# In the future this listener will handle executing the correct view handler based on the
# registered formats and the format that the initial `HTTP::Request` requires.
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

      if groups = configuration.serialization_groups
        if context_groups = context.groups
          context.groups = context_groups | groups
        else
          context.groups = groups
        end
      end
    end

    if view.format.nil?
      view.format = request.format
    end

    event.response = @view_handler.handle view, request
  end
end
