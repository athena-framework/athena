require "mime"

# Attempts to determine the best format for the current request based on its [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) `HTTP` header
# and the format priority configuration.
#
# `ATH::Request::FORMATS` is used to determine the related format from the request's `MIME` type.
#
# See the [Getting Started](/getting_started/routing#content-negotiation) docs for more information.
struct Athena::Framework::Listeners::Format
  def initialize(
    @format_negotiator : ATH::View::FormatNegotiator
  ); end

  @[AEDA::AsEventListener(priority: 34)]
  def on_request(event : ATH::Events::Request) : Nil
    request = event.request
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

    raise ATH::Exception::NotAcceptable.new "No matching accepted Response format could be determined." if format.nil?

    request.request_format = format
  rescue ex : ATH::Exception::StopFormatListener
    # ignore
  end
end
