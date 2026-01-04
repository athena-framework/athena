# Sets route parameters on the current request via an `ART::RequestMatcherInterface`.
#
# This listener is only functional when the `athena-routing` component is available.
struct Athena::HTTPKernel::Listeners::Routing
  @request_context : ART::RequestContext

  def initialize(
    @matcher : ART::Matcher::URLMatcherInterface | ART::Matcher::RequestMatcherInterface,
    request_context : ART::RequestContext? = nil,
  )
    @request_context = request_context || @matcher.context
  end

  @[AEDA::AsEventListener(priority: 32)]
  def on_request(event : AHK::Events::Request) : Nil
    request = event.request

    @request_context.apply request

    begin
      parameters = if @matcher.is_a? ART::Matcher::RequestMatcherInterface
                     @matcher.match request
                   else
                     @matcher.match request.path
                   end

      Log.info &.emit %(Matched route '#{matched_route = parameters["_route"]? || "n/a"}'),
        route: matched_route,
        route_parameters: parameters.to_h,
        request_uri: request.resource,
        method: request.method

      parameters.each { |k, v| request.attributes.set k, v }

      parameters.delete "_route"

      request.attributes.set "_route_params", parameters, ART::Parameters
    rescue ex : ART::Exception::ResourceNotFound
      message = "No route found for '#{request.method} #{request.resource}'"

      # This is misspelled on purpose, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer.
      if referrer = request.headers["referer"]? # spellchecker:disable-line
        message += " (from: '#{referrer}')"
      end

      message += "."

      raise AHK::Exception::NotFound.new message, ex
    rescue ex : ART::Exception::MethodNotAllowed
      raise AHK::Exception::MethodNotAllowed.new(
        ex.allowed_methods,
        %(No route found for '#{request.method} #{request.resource}': Method Not Allowed (Allow: #{ex.allowed_methods.join ", "}).),
        ex
      )
    end
  end
end
