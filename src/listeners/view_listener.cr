@[ADI::Register]
# The view listener attempts to resolve a non `ART::Response` into an `ART::Response`.
# Currently this is achieved by JSON serializing the controller action's resulting value;
# either via `Object#to_json` or `ASR::Serializer`, depending on what type the resulting value is.
#
# In the future this listener will handle executing the correct view handler based on the
# registered formats and the format that the initial `HTTP::Request` requires.
#
# TODO: Implement a format negotiation algorithm.
struct Athena::Routing::Listeners::View
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ART::Events::View => 25,
    }
  end

  def initialize(@serializer : ASR::SerializerInterface); end

  def call(event : ART::Events::View, dispatcher : AED::EventDispatcherInterface) : Nil
    action = event.request.action
    view_context = action.view_context

    if action.return_type == Nil
      # Return an empty response if the action's return type is `Nil`, using the specified status if a custom one was defined
      return event.response = ART::Response.new status: view_context.has_custom_status? ? view_context.status : HTTP::Status::NO_CONTENT, headers: get_headers
    end

    event.response = ART::Response.new(headers: get_headers, status: view_context.status) do |io|
      data = event.action_result

      # Still use `#to_json` for `JSON::Serializable`,
      # but prioritize `ASR::Serializable` if the type includes both.
      if data.is_a? JSON::Serializable && !data.is_a? ASR::Serializable
        data.to_json io
      else
        context = ASR::SerializationContext.new

        view_context.serialization_groups.try do |groups|
          context.groups = groups
        end

        view_context.version.try do |version|
          context.version = version
        end

        context.emit_nil = view_context.emit_nil

        @serializer.serialize data, :json, io, context
      end
    end
  end

  private def get_headers : HTTP::Headers
    HTTP::Headers{"content-type" => "application/json"}
  end
end
