# Provides basic routing functionality to an [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html).
#
# This type works as both a [HTTP::Handler](https://crystal-lang.org/api/HTTP/Handler.html) and
# an `ART::RouteCollection` that accepts a block that will handle that particular route.
#
# ```
# handler = ART::RoutingHandler.new
#
# # The `methods` property can be used to limit the route to a particular HTTP method.
# handler.add "new_article", ART::Route.new("/article", methods: "post") do |ctx|
#   pp ctx.request.body.try &.gets_to_end
# end
#
# # The match parameters from the route are passed to the callback as a `Hash(String, String?)`.
# handler.add "article", ART::Route.new("/article/{id<\\d+>}", methods: "get") do |ctx, params|
#   pp params # => {"_route" => "article", "id" => "10"}
# end
#
# # Call the `#compile` method when providing the handler to the handler array.
# server = HTTP::Server.new([
#   handler.compile,
# ])
#
# address = server.bind_tcp 8080
# puts "Listening on http://#{address}"
# server.listen
# ```
#
# NOTE: This handler should be the last one, as it is terminal.
#
# ## Bubbling Exceptions
#
# By default, requests that result in an exception, either from `Athena::Routing` or the callback block itself,
# are gracefully handled by returning a proper error response to the client via [HTTP::Server::Response#respond_with_status](https://crystal-lang.org/api/HTTP/Server/Response.html#respond_with_status%28status%3AHTTP%3A%3AStatus%2Cmessage%3AString%3F%3Dnil%29%3ANil-instance-method).
#
# You can set `bubble_exceptions: true` when instantiating the routing handler to have full control over the returned response.
# This would allow you to define your own [HTTP::Handler](https://crystal-lang.org/api/HTTP/Handler.html) that can rescue the exceptions and apply your custom logic for how to handle the error.
#
# ```
# class ErrorHandler
#   include HTTP::Handler
#
#   def call(context)
#     call_next context
#   rescue ex
#     # Do something based on the ex, such as rendering the appropriate template, etc.
#   end
# end
#
# handler = ART::RoutingHandler.new bubble_exceptions: true
#
# # Add the routes...
#
# # Have the `ErrorHandler` run _before_ the routing handler.
# server = HTTP::Server.new([
#   ErrorHandler.new,
#   handler.compile,
# ])
#
# address = server.bind_tcp 8080
# puts "Listening on http://#{address}"
# server.listen
# ```
class Athena::Routing::RoutingHandler
  include HTTP::Handler

  @handlers : Hash(String, Proc(HTTP::Server::Context, Hash(String, String?), Nil)) = {} of String => HTTP::Server::Context, Hash(String, String?) -> Nil

  # :nodoc:
  forward_missing_to @collection

  @collection : ART::RouteCollection

  def initialize(
    matcher : ART::Matcher::URLMatcherInterface? = nil,
    @collection : ART::RouteCollection = ART::RouteCollection.new,
    @bubble_exceptions : Bool = false
  )
    @matcher = matcher || ART::Matcher::URLMatcher.new ART::RequestContext.new
  end

  # :inherit:
  def call(context)
    request : ART::Request

    {% if @top_level.has_constant?("Athena") && Athena.has_constant?("Framework") && Athena::Framework.has_constant?("Request") %}
      request = ATH::Request.new context.request
    {% else %}
      request = context.request
    {% end %}

    @matcher.context.apply request

    begin
      parameters = if @matcher.is_a? ART::Matcher::RequestMatcherInterface
                     @matcher.match request
                   else
                     @matcher.match request.path
                   end
    rescue ex : ART::Exception::ResourceNotFound
      raise ex if @bubble_exceptions
      return context.response.respond_with_status(:not_found)
    rescue ex : ART::Exception::MethodNotAllowed
      raise ex if @bubble_exceptions
      return context.response.respond_with_status(:method_not_allowed)
    end

    begin
      @handlers[parameters["_route"]].call context, parameters
    rescue ex : ::Exception
      raise ex if @bubble_exceptions
      context.response.respond_with_status(:internal_server_error)
    end
  end

  # :nodoc:
  def add(collection : ART::RouteCollection) : NoReturn
    raise ArgumentError.new "Cannot add an existing collection to a routing handler."
  end

  # Adds the provided *route* with the provided *name* to this collection, optionally with the provided *priority*.
  # The passed *block* will be called when a request matching this route is encountered.
  def add(name : String, route : ART::Route, priority : Int32 = 0, &block : HTTP::Server::Context, Hash(String, String?) -> Nil) : Nil
    @handlers[name] = block
    @collection.add name, route, priority
  end

  # Helper method that calls `ART.compile` with the internal `ART::RouteCollection`,
  # and returns `self` to make setting up the routes easier.
  #
  # ```
  # handler = ART::RoutingHandler.new
  #
  # # Register routes
  #
  # server = HTTP::Server.new([
  #   handler.compile,
  # ])
  # ```
  def compile : self
    ART.compile @collection

    self
  end
end
