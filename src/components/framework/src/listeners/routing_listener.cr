@[ADI::Register]
# Sets the related `ATH::Action` on the current request via an `ART::RequestMatcherInterface`.
struct Athena::Framework::Listeners::Routing
  include AED::EventListenerInterface

  def self.subscribed_events : AED::SubscribedEvents
    AED::SubscribedEvents{
      ATH::Events::Request => 32,
    }
  end

  @request_context : ART::RequestContext

  def initialize(
    @matcher : ART::Matcher::URLMatcherInterface | ART::Matcher::RequestMatcherInterface,
    @request_store : ATH::RequestStore,
    request_context : ART::RequestContext? = nil
  )
    @request_context = request_context || @matcher.context
  end

  def call(event : ATH::Events::Request, dispatcher : AED::EventDispatcherInterface) : Nil
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
        route_parameters: parameters,
        request_uri: request.resource,
        method: request.method

      request.attributes.set parameters

      parameters.delete "_route"

      request.attributes.set "_route_params", parameters, Hash(String, String?)
    rescue ex : ART::Exception::ResourceNotFound
      message = "No route found for '#{request.method} #{request.resource}'"

      if referer = request.headers["referer"]?
        message += " (from: '#{referer}')"
      end

      message += "."

      raise ATH::Exceptions::NotFound.new message, ex
    rescue ex : ART::Exception::MethodNotAllowed
      raise ATH::Exceptions::MethodNotAllowed.new(
        ex.allowed_methods,
        %(No route found for '#{request.method} #{request.resource}': Method Not Allowed (Allow: #{ex.allowed_methods.join ", "}).),
        ex
      )
    end
  end
end
