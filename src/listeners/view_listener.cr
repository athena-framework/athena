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

    configuration = action.view_context

    view = event.action_result

    unless view.is_a? ART::View
      view = action.create_view view
    end

    # TODO: Apply the configuration from the View annotation onto the view instance

    if view.format.nil?
      view.format = request.format
    end

    event.response = @view_handler.handle view, request
  end
end
