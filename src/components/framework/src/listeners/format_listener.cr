require "mime"

@[ADI::Register]
# Attempts to determine the best format for the current request based on its [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) `HTTP` header
# and the format priority configuration.
#
# `ATH::Request::FORMATS` is used to determine the related format from the request's `MIME` type.
#
# See the [negotiation](/components/negotiation) component for more information.
struct Athena::Framework::Listeners::Format
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{ATH::Events::Request => 34}
  end

  def initialize(
    @config : ATH::Config::ContentNegotiation?,
    @format_negotiator : ATH::View::FormatNegotiator
  ); end

  def call(event : ATH::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
    request = event.request

    # Return early if there is no content_negotiation configuration.
    return unless @config

    format = request.request_format nil

    if format.nil?
      accept = @format_negotiator.best ""

      if !accept.nil? && 0.0 < accept.quality
        format = request.format accept.header

        unless format.nil?
          request.attributes.set "media_type", accept.header, String
        end
      end
    end

    raise ATH::Exceptions::NotAcceptable.new "No matching accepted Response format could be determined." if format.nil?

    request.request_format = format
  rescue ex : ATH::Exceptions::StopFormatListener
    # ignore
  end
end
