require "mime"

@[ADI::Register]
# TODO: Support customizing this listener more granularly.
# E.x. default format/priorities on a per route basis.
# Probably via something like how CORS can be configured,
# but TBD depending on how configuration is handled longer term.
struct Athena::Routing::Listeners::Format
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{ART::Events::Request => 34}
  end

  def initialize(
    @format_negotiator : ART::View::FormatNegotiator
  ); end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    # Return early if there are no configurations
    return unless @format_negotiator.enabled?

    format = request.request_format nil

    if format.nil?
      accept = @format_negotiator.best ""

      pp accept

      if !accept.nil? && 0.0 < accept.quality
        if format = request.format accept.header
          request.attributes.set "media_type", format, String
        end
      end
    end

    raise ART::Exceptions::NotAcceptable.new "No matching accepted Response format could be determined." if format.nil?

    request.request_format = format
  end
end
