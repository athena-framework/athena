require "mime"

@[ADI::Register]
# Attempts to determine the best format for the current request based on its [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) `HTTP` header
# and the format priority configuration.
#
# `ART::Request::FORMATS` is used to determine the related format from the request's `MIME` type.
#
# See the [negotiation](/components/negotiation) component for more information.
struct Athena::Routing::Listeners::Format
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{ART::Events::Request => 34}
  end

  def initialize(
    @config : ART::Config::ContentNegotiation?,
    @format_negotiator : ART::View::FormatNegotiator
  ); end

  def call(event : ART::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
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

    raise ART::Exceptions::NotAcceptable.new "No matching accepted Response format could be determined." if format.nil?

    request.request_format = format
  rescue ex : ART::Exceptions::StopFormatListener
    # ignore
  end
end
