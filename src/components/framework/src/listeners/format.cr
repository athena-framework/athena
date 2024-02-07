require "mime"

# See the [ATH::Bundle::FormatListener] for more information.
struct Athena::Framework::Listeners::Format
  include AED::EventListenerInterface

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

    raise ATH::Exceptions::NotAcceptable.new "No matching accepted Response format could be determined." if format.nil?

    request.request_format = format
  rescue ex : ATH::Exceptions::StopFormatListener
    # ignore
  end
end
