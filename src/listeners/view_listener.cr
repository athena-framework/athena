@[ADI::Register]
# The view listener attempts to resolve a non `ART::Response` into an `ART::Response`.
# Currently this is achieved by JSON serializing the controller action's resulting value.
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
    event.response = if event.request.route.return_type == Nil
                       ART::Response.new status: :no_content, headers: get_headers
                     else
                       ART::Response.new(headers: get_headers) do |io|
                         data = event.view.data

                         # Still use `#to_json` for `JSON::Serializable`,
                         # but prioritize `ASR::Serializable` if the type includes both.
                         if data.is_a? JSON::Serializable && !data.is_a? ASR::Serializable
                           data.to_json io
                         else
                           @serializer.serialize data, :json, io
                         end
                       end
                     end
  end

  private def get_headers : HTTP::Headers
    HTTP::Headers{"content-type" => "application/json"}
  end
end
